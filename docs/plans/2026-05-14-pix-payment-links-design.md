# PIX Payment Links — Design

**Date:** 2026-05-14
**Author:** Iago Cavalcante (with Claude Code)
**Status:** Approved, ready for implementation
**Origin:** Feature request from João Lubiem via Telegram, 2026-05-14. Example reference: https://cobranca.c6pix.com.br/01KRKC1FE6BAHE9WFGMGBP0YG6

## Summary

Add shareable PIX payment pages at `mepagueoque.dev/p/{slug}` to complement the existing email/WhatsApp charge flows. A user fills a form on `/criar` with PIX key + beneficiary + value + description (+ optional slug); the API stores the data, generates an EMV-BR `copia e cola` string with CRC16, and returns a canonical URL. Anyone with that URL sees a payment page with QR code, amount, beneficiary, description, and a copy-to-clipboard button.

## Goals

- Replace the "I'll build a quick site" workflow for one-off PIX collections (sports groups, splitting bills, etc.).
- Keep the create flow under 30 seconds: form → submit → shareable URL.
- Generate fully-compliant PIX EMV-BR payloads that work in every Brazilian banking app.
- Zero new operational burden (no separate database service, no auth system).

## Non-goals (explicit YAGNI)

- User accounts, login, edit-after-create, delete-after-create.
- View counters, "mark as paid" tracking, payment confirmation webhooks.
- Multi-region SQLite replication (mepagueoque is GRU-only).
- Custom theming, branded sub-pages, vanity domains.
- Bulk creation, API tokens for third-party use.

## Architectural decisions

| Decision | Choice | Why |
|---|---|---|
| Persistence | SQLite on a Fly volume | No new infra service. Mepagueoque is single-region. ~free. |
| Slug strategy | Optional custom, ULID fallback | Matches c6pix UX and João's request literally. |
| PIX fields | Full EMV-BR (key, name, city, desc, value) | Banks display placeholders like "PAGAMENTO" badly. |
| Create UX | Dedicated `/criar` page | Cleaner separation from the email/WhatsApp flow. |
| BR Code generation | Server-side in Elixir | Source of truth, easy to unit-test CRC. |
| Expiration | 90-day default, no UI control | Covers the volleyball use case; keeps DB bounded. |
| Abuse protection | Reuse Cloudflare Turnstile | Already integrated in the email flow. |

## System overview

```
┌──────────────────┐         ┌─────────────────────────────┐
│  Vue 3 (Vite)    │         │   Elixir API (Plug+Bandit)  │
│                  │         │                             │
│  / (existing)    │         │   POST /enviar-cobranca     │
│  /criar          │ ──HTTP─▶│   POST /pagamentos          │
│  /p/:slug        │         │   GET  /pagamentos/:slug    │
└──────────────────┘         │                             │
                             │   ┌─────────────────────┐   │
                             │   │ Pix.BrCode (EMV)    │   │
                             │   │ Pix.KeyType         │   │
                             │   │ ExpirationSweeper   │   │
                             │   └─────────────────────┘   │
                             │              │              │
                             │              ▼              │
                             │   ┌─────────────────────┐   │
                             │   │ SQLite via Ecto     │   │
                             │   │ /data/mepagueoque.db│   │
                             │   └─────────────────────┘   │
                             └─────────────────────────────┘
                                            │
                                            ▼
                                  ┌──────────────────┐
                                  │ Fly volume 1GB   │
                                  │ /data            │
                                  └──────────────────┘
```

## Backend — Elixir API

### Hex deps to add (`mix.exs`)

```elixir
{:ecto_sql, "~> 3.12"},
{:ecto_sqlite3, "~> 0.17"},
```

### Supervision tree change (`application.ex`)

Add `MepagueoqueApi.Repo` to `children` **before** Bandit so the DB is ready when HTTP starts accepting traffic.

### Database schema

Table `payment_links`:

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK | autoincrement |
| `slug` | TEXT NOT NULL UNIQUE | ULID auto, or user-provided `[a-z0-9-]{3,40}` |
| `pix_key` | TEXT NOT NULL | raw key as entered |
| `pix_key_type` | TEXT NOT NULL | `cpf` / `cnpj` / `email` / `phone` / `random` |
| `beneficiary_name` | TEXT NOT NULL | ≤25 chars, ASCII-folded |
| `city` | TEXT NOT NULL | ≤15 chars, ASCII-folded, default `BRASIL` |
| `description` | TEXT NOT NULL | ≤72 chars after ASCII-fold |
| `amount_cents` | INTEGER NOT NULL | positive integer cents |
| `inserted_at` | DATETIME NOT NULL | UTC |
| `expires_at` | DATETIME NOT NULL | `inserted_at + 90 days`, indexed |

Indexes: `UNIQUE(slug)`, `INDEX(expires_at)`.

### Module layout

```
lib/mepagueoque_api/
├── repo.ex                              # Ecto.Repo, SQLite3 adapter
├── release.ex                           # migrate/0 for release_command
├── schemas/
│   └── payment_link.ex                  # Ecto schema + changeset
├── pix/
│   ├── br_code.ex                       # EMV-BR TLV encoding + CRC16-CCITT
│   └── key_type.ex                      # detect key type from string
├── controllers/
│   └── payment_link_controller.ex       # create/2, show/2
└── workers/
    └── expiration_sweeper.ex            # Task running every 6h
```

### Routes (`router.ex`)

- `POST /pagamentos` — body `{pix_key, beneficiary_name, city, description, amount_cents, slug?, token}`
  - Returns `200 {slug, url, br_code, expires_at}` on success
  - `400` invalid params (per-field details)
  - `401` Turnstile failure
  - `409` slug collision
- `GET /pagamentos/:slug` — returns `200 {slug, beneficiary_name, description, amount_cents, br_code, expires_at}` or `404`.

### BR Code module (`Pix.BrCode`)

Pure Elixir implementation of the EMV-BR specification (BCB Manual de Padrões para Iniciação do PIX):
- TLV encoding with 2-digit ID + 2-digit length.
- Fields: Payload Format Indicator (00), Merchant Account Information (26 → GUI `br.gov.bcb.pix` + key), Merchant Category Code (52, default `0000`), Currency (53, `986`), Amount (54), Country (58, `BR`), Merchant Name (59), City (60), Additional Data Field (62 → Reference Label).
- CRC16-CCITT (poly `0x1021`, init `0xFFFF`) appended as field `63`.
- Unit tests use BCB manual fixtures + a roundtrip sanity check against `pix-utils` decoded JSON.

### Expiration sweeper

`Workers.ExpirationSweeper` — a `Task` started under the app supervisor that loops:

```elixir
def loop do
  Repo.delete_all(from p in PaymentLink, where: p.expires_at < ^DateTime.utc_now())
  Process.sleep(:timer.hours(6))
  loop()
end
```

No Oban/Quantum needed at this scale.

### Fly deployment

- `flyctl volumes create mepagueoque_data --region gru --size 1` (one-time).
- `fly.toml` adds `[mounts] source = "mepagueoque_data" destination = "/data"`.
- `Application.put_env` reads `DATABASE_PATH` (default `/data/mepagueoque.db`).
- `Dockerfile` release command: `bin/mepagueoque_api eval "MepagueoqueApi.Release.migrate()"` before server boot.

## Frontend — Vue 3

### New deps (`package.json`)

```json
"vue-router": "^4.4.0",
"qrcode": "^1.5.4"
```

### Router setup (`src/router/index.js`)

- `/` → existing `Index.vue` (untouched)
- `/criar` → `CreatePaymentPage.vue`
- `/p/:slug` → `PaymentPage.vue`
- catch-all → redirect to `/`

`main.js` mounts the router. `App.vue` replaces `<Index />` with `<router-view />`, keeping `Content` and `Footer` as layout chrome.

### `CreatePaymentPage.vue`

- Vuetify form fields: pix_key, beneficiary_name (max 25), city (max 15, default "BRASIL"), description (max 72), amount (BRL masked), slug (optional, helper "deixe em branco pra gerar automaticamente").
- Turnstile widget (reuse `vue-turnstile`).
- Submit → `POST {VITE_API_HOST}/pagamentos` → on 200 `router.push('/p/' + slug)`; on 409 inline error "esse slug já existe".
- Client-side hint when input contains accents that will be ASCII-folded.

### `PaymentPage.vue`

- On mount: `GET {VITE_API_HOST}/pagamentos/:slug`.
- Render: BRL-formatted amount, beneficiary, description, expiry date.
- QR via `QRCode.toCanvas(canvasRef, br_code, { width: 280 })`.
- "Copiar código PIX" button → `navigator.clipboard.writeText(br_code)` + toast.
- "Compartilhar" → `navigator.share({url: window.location.href})` with copy fallback.
- 404 state: "Esse link expirou ou não existe" + CTA back to `/criar`.

### Env vars

- New: `VITE_API_HOST` (Elixir API base URL).
- Existing `VITE_LAMBDA_HOST` stays for `/enviar-cobranca` compatibility, or rename in same PR.

## Edge cases & error handling

| Case | Behavior |
|---|---|
| Slug collision | API 409 → inline form error. ULID effectively can't collide. |
| Invalid PIX key | `Pix.KeyType` rejects → API 400 with `details: "chave_invalida"`. Format check only, no BCB lookup. |
| Accents in description | Server ASCII-folds for EMV; stored original; page displays original. |
| Amount ≤ 0 | API 400. |
| Expired link race | `show/2` filters `expires_at > now()` in query → 404 immediately. |
| Turnstile reuse | Same service module as `/enviar-cobranca`. |

## Testing strategy

**Backend (ExUnit):**
- `Pix.BrCodeTest` — fixture-driven against BCB manual examples (load-bearing).
- `Pix.KeyTypeTest` — table tests for valid/invalid per key type.
- `Schemas.PaymentLinkTest` — changeset validations.
- `Controllers.PaymentLinkControllerTest` — integration with SQL Sandbox + in-memory SQLite.
- `Workers.ExpirationSweeperTest` — insert expired + fresh rows, run once, assert.

**Frontend (Vitest):**
- `CreatePaymentPage.spec.js` — form validation, axios mock, redirect on success, 409 inline error.
- `PaymentPage.spec.js` — render states (loading/loaded/404), copy-to-clipboard with mocked navigator.

## Rollout plan

Ship in this order so nothing is half-deployed:

1. **Backend skeleton** — deps, Repo, schema, migration, `Pix.BrCode` + tests. Deploy. No new routes exposed yet.
2. **Backend routes** — controller, POST/GET routes, sweeper. Deploy. Smoke-test with `curl`.
3. **Frontend routing** — vue-router setup, `/criar` and `/p/:slug` pages. Deploy. Test end-to-end on staging.
4. **Homepage entry point** — add link to `/criar` from the existing home page. Small final commit.

## Open questions

None at design-approval time. All decisions confirmed interactively on 2026-05-14.
