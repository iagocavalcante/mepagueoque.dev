# PIX Payment Links — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build shareable `mepagueoque.dev/p/{slug}` PIX payment pages with a `/criar` create form, persisted in SQLite, server-generated EMV-BR `copia e cola`, and a 90-day TTL.

**Architecture:** Add Ecto + SQLite (Fly volume) to the existing Plug+Bandit Elixir API. New `Pix.BrCode` module produces the EMV-BR payload server-side. Vue 3 frontend adds `vue-router`, two new pages, and a QR rendering lib.

**Tech Stack:** Elixir 1.17 · Plug · Bandit · Ecto · SQLite3 · Vue 3 · Vuetify 3 · vue-router · qrcode

**Source design:** `docs/plans/2026-05-14-pix-payment-links-design.md` (on master)

**Working directory:** `/Users/iagocavalcante/Workspaces/IagoCavalcante/mepagueoque.dev/.worktrees/pix-payment-links`

**Branch:** `feature/pix-payment-links`

---

## Conventions for every task

- TDD: failing test → minimal implementation → passing test → commit.
- All Elixir test commands run from `mepagueoque_api/`. All frontend commands run from the worktree root.
- One commit per task unless noted. Conventional commit prefixes (`feat:`, `test:`, `chore:`).
- After each task: re-run the full suite (`mix test` and `yarn test --run`) to catch regressions.

---

# Phase 1 — Backend skeleton (no HTTP routes yet)

## Task 1: Add Ecto + SQLite dependencies

**Files:**
- Modify: `mepagueoque_api/mix.exs`

**Step 1 — Edit deps list**

Add to the `deps/0` function (alongside existing deps):

```elixir
{:ecto_sql, "~> 3.12"},
{:ecto_sqlite3, "~> 0.17"}
```

**Step 2 — Add `:ecto_sql` to `extra_applications`**

In the `application/0` function, change:

```elixir
extra_applications: [:logger, :crypto, :inets]
```

to:

```elixir
extra_applications: [:logger, :crypto, :inets, :ecto_sql]
```

**Step 3 — Install**

Run from `mepagueoque_api/`:
```bash
mix deps.get
```
Expected: hex fetches `ecto`, `ecto_sql`, `ecto_sqlite3`, `db_connection`, `exqlite`.

**Step 4 — Verify compiles**

```bash
mix compile
```
Expected: clean compile, no warnings about Ecto.

**Step 5 — Commit**

```bash
git add mix.exs mix.lock
git commit -m "chore: add ecto_sql and ecto_sqlite3 deps"
```

---

## Task 2: Configure Repo

**Files:**
- Create: `mepagueoque_api/lib/mepagueoque_api/repo.ex`
- Modify: `mepagueoque_api/config/config.exs`
- Modify: `mepagueoque_api/config/dev.exs`
- Modify: `mepagueoque_api/config/test.exs`
- Modify: `mepagueoque_api/config/runtime.exs`
- Modify: `mepagueoque_api/lib/mepagueoque_api/application.ex`

**Step 1 — Create Repo module**

`lib/mepagueoque_api/repo.ex`:
```elixir
defmodule MepagueoqueApi.Repo do
  use Ecto.Repo,
    otp_app: :mepagueoque_api,
    adapter: Ecto.Adapters.SQLite3
end
```

**Step 2 — Configure ecto_repos**

Add to `config/config.exs`:
```elixir
config :mepagueoque_api,
  ecto_repos: [MepagueoqueApi.Repo]
```

**Step 3 — Dev config**

Add to `config/dev.exs`:
```elixir
config :mepagueoque_api, MepagueoqueApi.Repo,
  database: Path.expand("../data/mepagueoque_dev.db", __DIR__),
  pool_size: 5,
  show_sensitive_data_on_connection_error: true
```

**Step 4 — Test config**

Add to `config/test.exs`:
```elixir
config :mepagueoque_api, MepagueoqueApi.Repo,
  database: ":memory:",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5
```

**Step 5 — Runtime (prod) config**

Add to `config/runtime.exs` under the prod section (only if `config_env() == :prod`):
```elixir
if config_env() == :prod do
  config :mepagueoque_api, MepagueoqueApi.Repo,
    database: System.get_env("DATABASE_PATH") || "/data/mepagueoque.db",
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
    journal_mode: :wal,
    cache_size: -64_000,
    temp_store: :memory,
    synchronous: :normal
end
```

**Step 6 — Add Repo to supervision tree**

Edit `lib/mepagueoque_api/application.ex`, prepend Repo before Bandit:

```elixir
children = [
  MepagueoqueApi.Repo,
  {Bandit, plug: MepagueoqueApi.Router, port: port, scheme: :http, ip: {0, 0, 0, 0}}
]
```

**Step 7 — Create local data dir**

```bash
mkdir -p data && echo "*.db*" > data/.gitignore && git add data/.gitignore
```

**Step 8 — Verify boot**

```bash
mix test
```
Expected: existing 21 tests still pass. SQLite in-memory DB starts cleanly.

**Step 9 — Commit**

```bash
git add lib/mepagueoque_api/repo.ex config/ lib/mepagueoque_api/application.ex data/.gitignore
git commit -m "feat: add Ecto Repo with SQLite3 adapter"
```

---

## Task 3: Create `payment_links` migration

**Files:**
- Create: `mepagueoque_api/priv/repo/migrations/20260514000001_create_payment_links.exs`

**Step 1 — Generate migration directory**

```bash
mkdir -p priv/repo/migrations
```

**Step 2 — Write migration**

```elixir
defmodule MepagueoqueApi.Repo.Migrations.CreatePaymentLinks do
  use Ecto.Migration

  def change do
    create table(:payment_links) do
      add :slug, :string, null: false
      add :pix_key, :string, null: false
      add :pix_key_type, :string, null: false
      add :beneficiary_name, :string, null: false
      add :city, :string, null: false
      add :description, :string, null: false
      add :amount_cents, :integer, null: false
      add :inserted_at, :utc_datetime, null: false
      add :expires_at, :utc_datetime, null: false
    end

    create unique_index(:payment_links, [:slug])
    create index(:payment_links, [:expires_at])
  end
end
```

**Step 3 — Run migration in dev**

```bash
mix ecto.create
mix ecto.migrate
```
Expected: `data/mepagueoque_dev.db` created, table exists.

**Step 4 — Verify with SQLite CLI**

```bash
sqlite3 data/mepagueoque_dev.db ".schema payment_links"
```
Expected: CREATE TABLE statement with all columns + 2 indexes.

**Step 5 — Verify tests still green**

```bash
mix test
```
Expected: 21 tests pass.

**Step 6 — Commit**

```bash
git add priv/repo/migrations/
git commit -m "feat: payment_links migration"
```

---

## Task 4: `Pix.KeyType` module — detect PIX key type

**Files:**
- Create: `mepagueoque_api/lib/mepagueoque_api/pix/key_type.ex`
- Create: `mepagueoque_api/test/mepagueoque_api/pix/key_type_test.exs`

**Step 1 — Write the failing test**

```elixir
defmodule MepagueoqueApi.Pix.KeyTypeTest do
  use ExUnit.Case, async: true
  alias MepagueoqueApi.Pix.KeyType

  describe "detect/1" do
    test "detects CPF (11 digits)" do
      assert {:ok, :cpf} = KeyType.detect("12345678909")
      assert {:ok, :cpf} = KeyType.detect("123.456.789-09")
    end

    test "detects CNPJ (14 digits)" do
      assert {:ok, :cnpj} = KeyType.detect("12345678000190")
      assert {:ok, :cnpj} = KeyType.detect("12.345.678/0001-90")
    end

    test "detects email" do
      assert {:ok, :email} = KeyType.detect("iago@mepagueoque.dev")
    end

    test "detects phone (E.164 with +55)" do
      assert {:ok, :phone} = KeyType.detect("+5511999998888")
    end

    test "detects random key (UUID v4)" do
      assert {:ok, :random} = KeyType.detect("123e4567-e89b-12d3-a456-426614174000")
    end

    test "rejects garbage" do
      assert {:error, :invalid_pix_key} = KeyType.detect("not a key")
      assert {:error, :invalid_pix_key} = KeyType.detect("")
      assert {:error, :invalid_pix_key} = KeyType.detect(nil)
    end
  end

  describe "normalize/2" do
    test "strips formatting from CPF" do
      assert "12345678909" = KeyType.normalize("123.456.789-09", :cpf)
    end

    test "strips formatting from CNPJ" do
      assert "12345678000190" = KeyType.normalize("12.345.678/0001-90", :cnpj)
    end

    test "leaves email lowercase" do
      assert "iago@mepagueoque.dev" = KeyType.normalize("IAGO@MePagueoQue.dev", :email)
    end

    test "leaves phone unchanged" do
      assert "+5511999998888" = KeyType.normalize("+5511999998888", :phone)
    end

    test "leaves random unchanged (lowercase)" do
      assert "123e4567-e89b-12d3-a456-426614174000" =
               KeyType.normalize("123E4567-E89B-12D3-A456-426614174000", :random)
    end
  end
end
```

**Step 2 — Run, confirm failure**

```bash
mix test test/mepagueoque_api/pix/key_type_test.exs
```
Expected: FAIL with `MepagueoqueApi.Pix.KeyType is undefined`.

**Step 3 — Implement**

`lib/mepagueoque_api/pix/key_type.ex`:
```elixir
defmodule MepagueoqueApi.Pix.KeyType do
  @moduledoc """
  Detects and normalizes PIX key types per BCB rules.

  Key types per BCB Pix manual:
    - :cpf — 11 digits
    - :cnpj — 14 digits
    - :email — RFC-ish, must contain @ and a dot in domain
    - :phone — E.164 starting with + (Brazilian numbers are +55…)
    - :random — UUID v4
  """

  @type key_type :: :cpf | :cnpj | :email | :phone | :random

  @uuid_re ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  @email_re ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
  @phone_re ~r/^\+\d{10,15}$/

  @spec detect(String.t() | nil) :: {:ok, key_type()} | {:error, :invalid_pix_key}
  def detect(key) when is_binary(key) and key != "" do
    cond do
      Regex.match?(@uuid_re, key) -> {:ok, :random}
      Regex.match?(@email_re, key) -> {:ok, :email}
      Regex.match?(@phone_re, key) -> {:ok, :phone}
      digit_count(key) == 11 and only_cpf_chars?(key) -> {:ok, :cpf}
      digit_count(key) == 14 and only_cnpj_chars?(key) -> {:ok, :cnpj}
      true -> {:error, :invalid_pix_key}
    end
  end

  def detect(_), do: {:error, :invalid_pix_key}

  @spec normalize(String.t(), key_type()) :: String.t()
  def normalize(key, :cpf), do: digits_only(key)
  def normalize(key, :cnpj), do: digits_only(key)
  def normalize(key, :email), do: String.downcase(key)
  def normalize(key, :phone), do: key
  def normalize(key, :random), do: String.downcase(key)

  defp digit_count(str), do: str |> digits_only() |> String.length()
  defp digits_only(str), do: String.replace(str, ~r/\D/, "")
  defp only_cpf_chars?(str), do: Regex.match?(~r/^[\d.\-]+$/, str)
  defp only_cnpj_chars?(str), do: Regex.match?(~r/^[\d.\-\/]+$/, str)
end
```

**Step 4 — Run, confirm pass**

```bash
mix test test/mepagueoque_api/pix/key_type_test.exs
```
Expected: all 9 tests pass.

**Step 5 — Commit**

```bash
git add lib/mepagueoque_api/pix/key_type.ex test/mepagueoque_api/pix/key_type_test.exs
git commit -m "feat(pix): detect and normalize PIX key types"
```

---

## Task 5: `Pix.BrCode` module — EMV-BR payload generator

This is the load-bearing module. The CRC and TLV structure must be exact.

**Files:**
- Create: `mepagueoque_api/lib/mepagueoque_api/pix/br_code.ex`
- Create: `mepagueoque_api/test/mepagueoque_api/pix/br_code_test.exs`

**Reference:** Banco Central do Brasil "Manual de Padrões para Iniciação do Pix" — TLV with 2-digit ID, 2-digit length (decimal), value. Final field is `63` = CRC16-CCITT/FALSE (poly `0x1021`, init `0xFFFF`, no reflection, no xor) of all preceding bytes including the literal string `"6304"`.

**Step 1 — Write the failing test**

```elixir
defmodule MepagueoqueApi.Pix.BrCodeTest do
  use ExUnit.Case, async: true
  alias MepagueoqueApi.Pix.BrCode

  describe "build/1" do
    test "generates known-good payload (email key)" do
      input = %{
        pix_key: "test@example.com",
        beneficiary_name: "FULANO DE TAL",
        city: "BRASILIA",
        description: "VOLEI 18/05",
        amount_cents: 1500
      }

      {:ok, payload} = BrCode.build(input)

      # Must start with PFI=01
      assert String.starts_with?(payload, "000201")
      # Must contain Merchant Account Information for PIX
      assert String.contains?(payload, "br.gov.bcb.pix")
      # Must contain the key
      assert String.contains?(payload, "test@example.com")
      # Must contain amount as "15.00"
      assert String.contains?(payload, "540515.00")
      # Country
      assert String.contains?(payload, "5802BR")
      # Merchant name
      assert String.contains?(payload, "FULANO DE TAL")
      # City
      assert String.contains?(payload, "BRASILIA")
      # Description (TXID-like Reference Label, ASCII-folded)
      assert String.contains?(payload, "VOLEI 18/05")
      # Ends with CRC field 63 (4 hex chars)
      assert Regex.match?(~r/6304[0-9A-F]{4}$/, payload)
    end

    test "ASCII-folds accents in description and name" do
      input = %{
        pix_key: "test@example.com",
        beneficiary_name: "JOÃO PÃO",
        city: "SÃO PAULO",
        description: "CARIPÚNAS",
        amount_cents: 100
      }

      {:ok, payload} = BrCode.build(input)
      assert String.contains?(payload, "JOAO PAO")
      assert String.contains?(payload, "SAO PAULO")
      assert String.contains?(payload, "CARIPUNAS")
      refute String.contains?(payload, "Ã")
      refute String.contains?(payload, "Ú")
    end

    test "amount formatting: cents to '12.34'" do
      assert {:ok, payload} = BrCode.build(base_input(amount_cents: 1234))
      assert String.contains?(payload, "54051234")  # length=5, "12.34"
    end

    test "amount formatting: round numbers as '100.00'" do
      assert {:ok, payload} = BrCode.build(base_input(amount_cents: 10_000))
      assert String.contains?(payload, "5406100.00")  # length=6
    end

    test "CRC is valid (round-trip check)" do
      {:ok, payload} = BrCode.build(base_input())
      assert BrCode.valid_crc?(payload)
    end

    test "rejects negative or zero amount" do
      assert {:error, :invalid_amount} = BrCode.build(base_input(amount_cents: 0))
      assert {:error, :invalid_amount} = BrCode.build(base_input(amount_cents: -5))
    end

    test "rejects beneficiary_name >25 chars" do
      long = String.duplicate("A", 26)
      assert {:error, :beneficiary_name_too_long} = BrCode.build(base_input(beneficiary_name: long))
    end

    test "rejects city >15 chars" do
      long = String.duplicate("A", 16)
      assert {:error, :city_too_long} = BrCode.build(base_input(city: long))
    end

    test "rejects description >72 chars" do
      long = String.duplicate("A", 73)
      assert {:error, :description_too_long} = BrCode.build(base_input(description: long))
    end
  end

  describe "valid_crc?/1" do
    test "true for self-generated payload" do
      {:ok, payload} = BrCode.build(base_input())
      assert BrCode.valid_crc?(payload)
    end

    test "false when CRC is corrupted" do
      {:ok, payload} = BrCode.build(base_input())
      corrupted = String.replace_suffix(payload, String.slice(payload, -4..-1), "0000")
      refute BrCode.valid_crc?(corrupted)
    end
  end

  defp base_input(overrides \\ []) do
    Map.merge(
      %{
        pix_key: "test@example.com",
        beneficiary_name: "FULANO",
        city: "BRASILIA",
        description: "TESTE",
        amount_cents: 1500
      },
      Map.new(overrides)
    )
  end
end
```

**Step 2 — Run, confirm failure**

```bash
mix test test/mepagueoque_api/pix/br_code_test.exs
```
Expected: all tests fail (module undefined).

**Step 3 — Implement**

`lib/mepagueoque_api/pix/br_code.ex`:
```elixir
defmodule MepagueoqueApi.Pix.BrCode do
  @moduledoc """
  EMV-BR `copia e cola` payload generator for PIX static QR codes.

  Implements the BCB "Manual de Padrões para Iniciação do Pix" TLV format
  with CRC16-CCITT/FALSE (poly 0x1021, init 0xFFFF, no reflection).
  """

  @gui "br.gov.bcb.pix"
  @currency_brl "986"
  @country_br "BR"
  @merchant_category "0000"
  @max_name 25
  @max_city 15
  @max_description 72

  @type input :: %{
          required(:pix_key) => String.t(),
          required(:beneficiary_name) => String.t(),
          required(:city) => String.t(),
          required(:description) => String.t(),
          required(:amount_cents) => pos_integer()
        }

  @spec build(input()) ::
          {:ok, String.t()}
          | {:error,
             :invalid_amount
             | :beneficiary_name_too_long
             | :city_too_long
             | :description_too_long}
  def build(%{amount_cents: amt}) when not is_integer(amt) or amt <= 0,
    do: {:error, :invalid_amount}

  def build(%{beneficiary_name: name} = input) do
    folded_name = ascii_fold(name)

    cond do
      String.length(folded_name) > @max_name ->
        {:error, :beneficiary_name_too_long}

      String.length(ascii_fold(input.city)) > @max_city ->
        {:error, :city_too_long}

      String.length(ascii_fold(input.description)) > @max_description ->
        {:error, :description_too_long}

      true ->
        do_build(input)
    end
  end

  defp do_build(input) do
    payload =
      [
        tlv("00", "01"),
        merchant_account(input.pix_key, ascii_fold(input.description)),
        tlv("52", @merchant_category),
        tlv("53", @currency_brl),
        tlv("54", format_amount(input.amount_cents)),
        tlv("58", @country_br),
        tlv("59", ascii_fold(input.beneficiary_name)),
        tlv("60", ascii_fold(input.city)),
        additional_data(ascii_fold(input.description))
      ]
      |> IO.iodata_to_binary()

    with_crc = payload <> "6304"
    crc = crc16(with_crc)
    {:ok, with_crc <> crc}
  end

  @spec valid_crc?(String.t()) :: boolean()
  def valid_crc?(payload) when byte_size(payload) > 4 do
    {body, given_crc} = String.split_at(payload, -4)
    expected = crc16(body)
    String.upcase(given_crc) == expected
  end

  def valid_crc?(_), do: false

  # ── TLV helpers ────────────────────────────────────────────────────────────

  defp tlv(id, value) do
    len = value |> byte_size() |> Integer.to_string() |> String.pad_leading(2, "0")
    id <> len <> value
  end

  defp merchant_account(pix_key, _txid_hint) do
    inner = tlv("00", @gui) <> tlv("01", pix_key)
    tlv("26", inner)
  end

  defp additional_data(description) do
    txid = sanitize_txid(description)
    tlv("62", tlv("05", txid))
  end

  defp sanitize_txid(text) do
    text
    |> String.replace(~r/[^A-Za-z0-9 \/.-]/, "")
    |> String.slice(0, 25)
    |> case do
      "" -> "***"
      v -> v
    end
  end

  defp format_amount(cents) do
    reais = div(cents, 100)
    rem_ = rem(cents, 100)
    "#{reais}." <> String.pad_leading(Integer.to_string(rem_), 2, "0")
  end

  # ── CRC16-CCITT/FALSE ──────────────────────────────────────────────────────

  defp crc16(binary) when is_binary(binary) do
    binary
    |> :binary.bin_to_list()
    |> Enum.reduce(0xFFFF, &crc_byte/2)
    |> Bitwise.band(0xFFFF)
    |> Integer.to_string(16)
    |> String.upcase()
    |> String.pad_leading(4, "0")
  end

  defp crc_byte(byte, crc) do
    crc = Bitwise.bxor(crc, Bitwise.bsl(byte, 8))
    Enum.reduce(1..8, crc, fn _, acc ->
      if Bitwise.band(acc, 0x8000) != 0 do
        Bitwise.bxor(Bitwise.bsl(acc, 1), 0x1021)
      else
        Bitwise.bsl(acc, 1)
      end
      |> Bitwise.band(0xFFFF)
    end)
  end

  # ── ASCII folding ──────────────────────────────────────────────────────────

  @folds %{
    "á" => "a", "à" => "a", "â" => "a", "ã" => "a", "ä" => "a",
    "é" => "e", "è" => "e", "ê" => "e", "ë" => "e",
    "í" => "i", "ì" => "i", "î" => "i", "ï" => "i",
    "ó" => "o", "ò" => "o", "ô" => "o", "õ" => "o", "ö" => "o",
    "ú" => "u", "ù" => "u", "û" => "u", "ü" => "u",
    "ç" => "c", "ñ" => "n",
    "Á" => "A", "À" => "A", "Â" => "A", "Ã" => "A", "Ä" => "A",
    "É" => "E", "È" => "E", "Ê" => "E", "Ë" => "E",
    "Í" => "I", "Ì" => "I", "Î" => "I", "Ï" => "I",
    "Ó" => "O", "Ò" => "O", "Ô" => "O", "Õ" => "O", "Ö" => "O",
    "Ú" => "U", "Ù" => "U", "Û" => "U", "Ü" => "U",
    "Ç" => "C", "Ñ" => "N"
  }

  defp ascii_fold(nil), do: ""

  defp ascii_fold(s) when is_binary(s) do
    s
    |> String.graphemes()
    |> Enum.map(&Map.get(@folds, &1, &1))
    |> Enum.join()
    |> String.replace(~r/[^\x20-\x7E]/, "")
  end
end
```

**Step 4 — Run, confirm pass**

```bash
mix test test/mepagueoque_api/pix/br_code_test.exs
```
Expected: all 11 tests pass.

**Step 5 — Manual sanity check (optional but recommended)**

In `iex -S mix`:
```elixir
{:ok, p} = MepagueoqueApi.Pix.BrCode.build(%{pix_key: "iago@mepagueoque.dev", beneficiary_name: "IAGO C", city: "BELEM", description: "TESTE", amount_cents: 100})
IO.puts(p)
```
Paste output into any PIX QR decoder (e.g. `qrcode-monkey` decoder) and confirm the bank app reads it correctly.

**Step 6 — Commit**

```bash
git add lib/mepagueoque_api/pix/br_code.ex test/mepagueoque_api/pix/br_code_test.exs
git commit -m "feat(pix): EMV-BR payload generator with CRC16-CCITT"
```

---

## Task 6: `Schemas.PaymentLink` Ecto schema

**Files:**
- Create: `mepagueoque_api/lib/mepagueoque_api/schemas/payment_link.ex`
- Create: `mepagueoque_api/test/mepagueoque_api/schemas/payment_link_test.exs`

**Step 1 — Write tests**

```elixir
defmodule MepagueoqueApi.Schemas.PaymentLinkTest do
  use ExUnit.Case, async: true
  alias MepagueoqueApi.Schemas.PaymentLink

  describe "changeset/2" do
    test "valid with all fields" do
      changeset = PaymentLink.changeset(%PaymentLink{}, valid_attrs())
      assert changeset.valid?
    end

    test "auto-generates slug when blank" do
      attrs = valid_attrs() |> Map.delete(:slug)
      changeset = PaymentLink.changeset(%PaymentLink{}, attrs)
      assert changeset.valid?
      slug = Ecto.Changeset.get_field(changeset, :slug)
      assert is_binary(slug)
      assert String.length(slug) == 26  # ULID-like
    end

    test "rejects slug with invalid chars" do
      changeset = PaymentLink.changeset(%PaymentLink{}, %{valid_attrs() | slug: "has spaces"})
      refute changeset.valid?
      assert "deve conter apenas letras minúsculas, números e hífens" in errors_on(changeset).slug
    end

    test "rejects slug shorter than 3 chars" do
      changeset = PaymentLink.changeset(%PaymentLink{}, %{valid_attrs() | slug: "ab"})
      refute changeset.valid?
    end

    test "rejects slug longer than 40 chars" do
      changeset = PaymentLink.changeset(%PaymentLink{}, %{valid_attrs() | slug: String.duplicate("a", 41)})
      refute changeset.valid?
    end

    test "rejects invalid pix_key" do
      changeset = PaymentLink.changeset(%PaymentLink{}, %{valid_attrs() | pix_key: "garbage"})
      refute changeset.valid?
      assert "chave PIX inválida" in errors_on(changeset).pix_key
    end

    test "rejects amount_cents <= 0" do
      changeset = PaymentLink.changeset(%PaymentLink{}, %{valid_attrs() | amount_cents: 0})
      refute changeset.valid?
    end

    test "auto-sets expires_at to inserted_at + 90 days" do
      changeset = PaymentLink.changeset(%PaymentLink{}, valid_attrs())
      assert changeset.valid?
      inserted = Ecto.Changeset.get_field(changeset, :inserted_at)
      expires = Ecto.Changeset.get_field(changeset, :expires_at)
      assert DateTime.diff(expires, inserted, :day) == 90
    end

    test "sets pix_key_type from key" do
      changeset = PaymentLink.changeset(%PaymentLink{}, valid_attrs())
      assert Ecto.Changeset.get_field(changeset, :pix_key_type) == "email"
    end
  end

  defp valid_attrs do
    %{
      slug: "volei",
      pix_key: "iago@example.com",
      beneficiary_name: "IAGO",
      city: "BELEM",
      description: "VOLEI",
      amount_cents: 1500
    }
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
```

**Step 2 — Run, confirm fail**

```bash
mix test test/mepagueoque_api/schemas/payment_link_test.exs
```
Expected: fail (module undefined).

**Step 3 — Implement**

`lib/mepagueoque_api/schemas/payment_link.ex`:
```elixir
defmodule MepagueoqueApi.Schemas.PaymentLink do
  use Ecto.Schema
  import Ecto.Changeset

  alias MepagueoqueApi.Pix.KeyType

  @ttl_days 90
  @slug_regex ~r/^[a-z0-9-]+$/

  @primary_key {:id, :id, autogenerate: true}
  schema "payment_links" do
    field :slug, :string
    field :pix_key, :string
    field :pix_key_type, :string
    field :beneficiary_name, :string
    field :city, :string
    field :description, :string
    field :amount_cents, :integer
    field :inserted_at, :utc_datetime
    field :expires_at, :utc_datetime
  end

  @required_for_create [:pix_key, :beneficiary_name, :city, :description, :amount_cents]
  @optional_for_create [:slug]

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required_for_create ++ @optional_for_create)
    |> validate_required(@required_for_create)
    |> validate_length(:beneficiary_name, max: 25)
    |> validate_length(:city, max: 15)
    |> validate_length(:description, max: 72)
    |> validate_number(:amount_cents, greater_than: 0)
    |> put_default(:city, "BRASIL")
    |> generate_slug_if_blank()
    |> validate_format(:slug, @slug_regex,
      message: "deve conter apenas letras minúsculas, números e hífens"
    )
    |> validate_length(:slug, min: 3, max: 40)
    |> set_pix_key_type()
    |> set_timestamps()
  end

  defp put_default(changeset, field, default) do
    case get_field(changeset, field) do
      nil -> put_change(changeset, field, default)
      "" -> put_change(changeset, field, default)
      _ -> changeset
    end
  end

  defp generate_slug_if_blank(changeset) do
    case get_field(changeset, :slug) do
      nil -> put_change(changeset, :slug, generate_ulid())
      "" -> put_change(changeset, :slug, generate_ulid())
      _ -> changeset
    end
  end

  defp generate_ulid do
    # Crockford base32 ULID: 10 chars timestamp + 16 chars random
    ts = System.system_time(:millisecond) |> encode_crockford(10)
    rand = :crypto.strong_rand_bytes(10) |> :binary.decode_unsigned() |> encode_crockford(16)
    String.downcase(ts <> rand)
  end

  @crockford "0123456789abcdefghjkmnpqrstvwxyz"

  defp encode_crockford(int, len) do
    do_encode(int, "")
    |> String.pad_leading(len, "0")
  end

  defp do_encode(0, acc), do: acc

  defp do_encode(int, acc) do
    char = String.at(@crockford, rem(int, 32))
    do_encode(div(int, 32), char <> acc)
  end

  defp set_pix_key_type(changeset) do
    case get_field(changeset, :pix_key) do
      nil ->
        changeset

      key ->
        case KeyType.detect(key) do
          {:ok, type} ->
            normalized = KeyType.normalize(key, type)

            changeset
            |> put_change(:pix_key, normalized)
            |> put_change(:pix_key_type, Atom.to_string(type))

          {:error, _} ->
            add_error(changeset, :pix_key, "chave PIX inválida")
        end
    end
  end

  defp set_timestamps(changeset) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expires = DateTime.add(now, @ttl_days * 86_400, :second)

    changeset
    |> put_change(:inserted_at, now)
    |> put_change(:expires_at, expires)
  end
end
```

**Step 4 — Run, confirm pass**

```bash
mix test test/mepagueoque_api/schemas/payment_link_test.exs
```
Expected: 9 tests pass.

**Step 5 — Commit**

```bash
git add lib/mepagueoque_api/schemas/payment_link.ex test/mepagueoque_api/schemas/payment_link_test.exs
git commit -m "feat: PaymentLink schema with ULID slug + 90d TTL"
```

---

# Phase 2 — Backend HTTP routes

## Task 7: `PaymentLinkController.create/2`

**Files:**
- Create: `mepagueoque_api/lib/mepagueoque_api/controllers/payment_link_controller.ex`
- Create: `mepagueoque_api/test/mepagueoque_api/controllers/payment_link_controller_test.exs`
- Create: `mepagueoque_api/test/support/data_case.ex`
- Modify: `mepagueoque_api/mix.exs` (add `elixirc_paths` for test env to include `test/support`)
- Modify: `mepagueoque_api/test/test_helper.exs`

**Step 1 — Add `elixirc_paths` for test env**

In `mix.exs`, after `def project`, add:
```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]
```

And in the project keyword list, add:
```elixir
elixirc_paths: elixirc_paths(Mix.env()),
```

**Step 2 — Create `test/support/data_case.ex`**

```elixir
defmodule MepagueoqueApi.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias MepagueoqueApi.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import MepagueoqueApi.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MepagueoqueApi.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
```

**Step 3 — Update `test/test_helper.exs`**

```elixir
ExUnit.start()

# Migrate in-memory DB once at test startup
Ecto.Adapters.SQL.Sandbox.mode(MepagueoqueApi.Repo, :manual)
{:ok, _} = Ecto.Migrator.run(MepagueoqueApi.Repo, Path.expand("../priv/repo/migrations", __DIR__), :up, all: true)
```

**Step 4 — Write failing test**

`test/mepagueoque_api/controllers/payment_link_controller_test.exs`:
```elixir
defmodule MepagueoqueApi.Controllers.PaymentLinkControllerTest do
  use MepagueoqueApi.DataCase, async: true
  alias MepagueoqueApi.Controllers.PaymentLinkController
  alias MepagueoqueApi.Schemas.PaymentLink

  import Mox

  setup :verify_on_exit!

  describe "create/2 (Turnstile bypassed in test)" do
    test "creates row with auto-slug" do
      params = %{
        "pix_key" => "iago@example.com",
        "beneficiary_name" => "IAGO",
        "city" => "BELEM",
        "description" => "VOLEI",
        "amount_cents" => 1500,
        "token" => "bypass"
      }

      assert {:ok, %{slug: slug, br_code: br_code, expires_at: expires_at}} =
               PaymentLinkController.create(build_conn(), params)

      assert is_binary(slug) and String.length(slug) >= 3
      assert String.contains?(br_code, "iago@example.com")
      assert %DateTime{} = expires_at
      assert Repo.get_by(PaymentLink, slug: slug)
    end

    test "honors user-provided slug" do
      params = base_params(%{"slug" => "voleizinho"})
      assert {:ok, %{slug: "voleizinho"}} = PaymentLinkController.create(build_conn(), params)
    end

    test "rejects slug collision with :slug_taken" do
      _ = PaymentLinkController.create(build_conn(), base_params(%{"slug" => "dup"}))
      assert {:error, :slug_taken} = PaymentLinkController.create(build_conn(), base_params(%{"slug" => "dup"}))
    end

    test "rejects invalid params with :invalid_params" do
      assert {:error, :invalid_params, _errors} =
               PaymentLinkController.create(build_conn(), %{"token" => "bypass"})
    end
  end

  defp build_conn do
    %Plug.Conn{remote_ip: {127, 0, 0, 1}, req_headers: []}
  end

  defp base_params(overrides) do
    Map.merge(
      %{
        "pix_key" => "iago@example.com",
        "beneficiary_name" => "IAGO",
        "city" => "BELEM",
        "description" => "VOLEI",
        "amount_cents" => 1500,
        "token" => "bypass"
      },
      overrides
    )
  end
end
```

**Step 5 — Configure Turnstile bypass in test**

Add to `config/test.exs`:
```elixir
config :mepagueoque_api, :turnstile_bypass_token, "bypass"
```

**Step 6 — Implement controller**

`lib/mepagueoque_api/controllers/payment_link_controller.ex`:
```elixir
defmodule MepagueoqueApi.Controllers.PaymentLinkController do
  @moduledoc """
  Create + fetch payment links.
  """

  require Logger
  alias MepagueoqueApi.{Repo, Pix.BrCode, Schemas.PaymentLink, Services.Turnstile}

  @type create_error ::
          {:error, :invalid_params, map()}
          | {:error, :slug_taken}
          | {:error, :turnstile_verification_failed, String.t()}
          | {:error, :internal_error, String.t()}

  @spec create(Plug.Conn.t(), map()) ::
          {:ok, %{slug: String.t(), br_code: String.t(), expires_at: DateTime.t()}}
          | create_error()
  def create(conn, params) do
    with {:ok, _} <- verify_turnstile(conn, params),
         {:ok, link} <- insert_link(params),
         {:ok, br_code} <- build_br_code(link) do
      {:ok, %{slug: link.slug, br_code: br_code, expires_at: link.expires_at}}
    end
  end

  defp verify_turnstile(conn, %{"token" => token}) do
    bypass = Application.get_env(:mepagueoque_api, :turnstile_bypass_token)

    if bypass && token == bypass do
      {:ok, :bypassed}
    else
      ip = client_ip(conn)

      case Turnstile.verify(token, ip) do
        {:ok, data} -> {:ok, data}
        {:error, reason} -> {:error, :turnstile_verification_failed, reason}
      end
    end
  end

  defp verify_turnstile(_, _), do: {:error, :turnstile_verification_failed, "missing token"}

  defp insert_link(params) do
    changeset = PaymentLink.changeset(%PaymentLink{}, normalize_keys(params))

    case Repo.insert(changeset) do
      {:ok, link} ->
        {:ok, link}

      {:error, %Ecto.Changeset{errors: [slug: {_, [constraint: :unique, _: _]}]}} ->
        {:error, :slug_taken}

      {:error, %Ecto.Changeset{} = cs} ->
        if Keyword.has_key?(cs.errors, :slug) and slug_unique_error?(cs.errors[:slug]) do
          {:error, :slug_taken}
        else
          {:error, :invalid_params, format_errors(cs)}
        end
    end
  end

  defp slug_unique_error?({_, opts}), do: Keyword.get(opts, :constraint) == :unique
  defp slug_unique_error?(_), do: false

  defp build_br_code(link) do
    case BrCode.build(%{
           pix_key: link.pix_key,
           beneficiary_name: link.beneficiary_name,
           city: link.city,
           description: link.description,
           amount_cents: link.amount_cents
         }) do
      {:ok, code} -> {:ok, code}
      {:error, reason} -> {:error, :internal_error, "BR Code build failed: #{reason}"}
    end
  end

  defp normalize_keys(params) do
    Map.new(params, fn {k, v} -> {if(is_binary(k), do: String.to_existing_atom(k), else: k), v} end)
  rescue
    ArgumentError -> params
  end

  defp format_errors(%Ecto.Changeset{errors: errors}) do
    Map.new(errors, fn {field, {msg, _}} -> {field, msg} end)
  end

  defp client_ip(%Plug.Conn{} = conn) do
    cond do
      ip = Plug.Conn.get_req_header(conn, "fly-client-ip") |> List.first() -> ip
      ip = Plug.Conn.get_req_header(conn, "cf-connecting-ip") |> List.first() -> ip
      true ->
        case conn.remote_ip do
          {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
          _ -> nil
        end
    end
  end
end
```

**Step 7 — Add slug unique_constraint to schema**

In `lib/mepagueoque_api/schemas/payment_link.ex`, append at end of `changeset/2` pipeline:
```elixir
|> unique_constraint(:slug)
```

**Step 8 — Run all tests**

```bash
mix test
```
Expected: all tests pass (existing 21 + new ones).

**Step 9 — Commit**

```bash
git add lib/mepagueoque_api/controllers/payment_link_controller.ex test/ mix.exs config/test.exs lib/mepagueoque_api/schemas/payment_link.ex
git commit -m "feat: PaymentLinkController.create with Turnstile + sandbox setup"
```

---

## Task 8: `PaymentLinkController.show/2`

**Files:**
- Modify: `mepagueoque_api/lib/mepagueoque_api/controllers/payment_link_controller.ex`
- Modify: `mepagueoque_api/test/mepagueoque_api/controllers/payment_link_controller_test.exs`

**Step 1 — Add failing test**

Append to `payment_link_controller_test.exs`:
```elixir
describe "show/1" do
  test "returns link payload + BR code" do
    {:ok, %{slug: slug}} = PaymentLinkController.create(build_conn(), base_params(%{"slug" => "live"}))
    assert {:ok, payload} = PaymentLinkController.show(slug)

    assert payload.slug == "live"
    assert payload.beneficiary_name == "IAGO"
    assert payload.description == "VOLEI"
    assert payload.amount_cents == 1500
    assert String.contains?(payload.br_code, "iago@example.com")
    assert %DateTime{} = payload.expires_at
  end

  test "returns :not_found when slug missing" do
    assert {:error, :not_found} = PaymentLinkController.show("nope")
  end

  test "returns :not_found for expired link" do
    {:ok, %{slug: slug}} = PaymentLinkController.create(build_conn(), base_params(%{"slug" => "old"}))
    past = DateTime.add(DateTime.utc_now(), -1, :second)
    Repo.update_all(from(p in PaymentLink, where: p.slug == ^slug), set: [expires_at: past])
    assert {:error, :not_found} = PaymentLinkController.show("old")
  end
end
```

Add at top of file:
```elixir
import Ecto.Query
```

**Step 2 — Implement `show/1`**

In `payment_link_controller.ex`:
```elixir
import Ecto.Query

@spec show(String.t()) ::
        {:ok, %{slug: String.t(), beneficiary_name: String.t(), description: String.t(),
                amount_cents: integer(), br_code: String.t(), expires_at: DateTime.t()}}
        | {:error, :not_found}
def show(slug) when is_binary(slug) do
  now = DateTime.utc_now()

  query =
    from p in PaymentLink,
      where: p.slug == ^slug and p.expires_at > ^now

  case Repo.one(query) do
    nil ->
      {:error, :not_found}

    link ->
      case build_br_code(link) do
        {:ok, br_code} ->
          {:ok,
           %{
             slug: link.slug,
             beneficiary_name: link.beneficiary_name,
             description: link.description,
             amount_cents: link.amount_cents,
             br_code: br_code,
             expires_at: link.expires_at
           }}

        {:error, :internal_error, _} ->
          {:error, :not_found}
      end
  end
end
```

**Step 3 — Run, confirm pass**

```bash
mix test test/mepagueoque_api/controllers/payment_link_controller_test.exs
```
Expected: all tests pass.

**Step 4 — Commit**

```bash
git add lib/mepagueoque_api/controllers/payment_link_controller.ex test/mepagueoque_api/controllers/payment_link_controller_test.exs
git commit -m "feat: PaymentLinkController.show with TTL filter"
```

---

## Task 9: Wire HTTP routes

**Files:**
- Modify: `mepagueoque_api/lib/mepagueoque_api/router.ex`

**Step 1 — Add routes**

In `router.ex`, after the existing `post "/enviar-cobranca"` block:

```elixir
alias MepagueoqueApi.Controllers.PaymentLinkController

options "/pagamentos" do
  send_resp(conn, 200, "")
end

post "/pagamentos" do
  case parse_body(conn) do
    {:ok, params} -> handle_create_payment(conn, params)
    {:error, reason} ->
      conn |> put_resp_content_type("application/json") |> send_resp(400, Jason.encode!(%{error: reason}))
  end
end

get "/pagamentos/:slug" do
  case PaymentLinkController.show(slug) do
    {:ok, payload} ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(payload))

    {:error, :not_found} ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(404, Jason.encode!(%{error: "not_found"}))
  end
end
```

**Step 2 — Implement `handle_create_payment/2`**

At the bottom of the module (in the private functions area):
```elixir
defp handle_create_payment(conn, params) do
  case PaymentLinkController.create(conn, params) do
    {:ok, payload} ->
      body = Map.put(payload, :url, "https://mepagueoque.dev/p/#{payload.slug}")

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(body))

    {:error, :invalid_params, errors} ->
      conn |> put_resp_content_type("application/json") |> send_resp(400, Jason.encode!(%{error: "invalid_params", details: errors}))

    {:error, :slug_taken} ->
      conn |> put_resp_content_type("application/json") |> send_resp(409, Jason.encode!(%{error: "slug_taken"}))

    {:error, :turnstile_verification_failed, reason} ->
      conn |> put_resp_content_type("application/json") |> send_resp(401, Jason.encode!(%{error: "turnstile_failed", details: reason}))

    {:error, _type, reason} ->
      conn |> put_resp_content_type("application/json") |> send_resp(500, Jason.encode!(%{error: "internal_error", details: reason}))
  end
end
```

**Step 3 — Smoke test with curl**

Start dev server in another terminal:
```bash
mix phx.server  # or: iex -S mix
```

Then:
```bash
curl -X POST http://localhost:4000/pagamentos \
  -H "Content-Type: application/json" \
  -d '{"pix_key":"iago@example.com","beneficiary_name":"IAGO","city":"BELEM","description":"VOLEI","amount_cents":1500,"token":"bypass"}'
```
Expected: 200 with `{slug, url, br_code, expires_at}`. (Set `TURNSTILE_BYPASS_TOKEN=bypass` or similar in dev if your config layers don't expose it — alternatively, temporarily mirror the test config bypass into dev.)

```bash
curl http://localhost:4000/pagamentos/<slug-from-above>
```
Expected: 200 with the payload.

```bash
curl -i http://localhost:4000/pagamentos/nope
```
Expected: 404.

**Step 4 — Commit**

```bash
git add lib/mepagueoque_api/router.ex
git commit -m "feat: wire POST/GET /pagamentos routes"
```

---

## Task 10: `Workers.ExpirationSweeper`

**Files:**
- Create: `mepagueoque_api/lib/mepagueoque_api/workers/expiration_sweeper.ex`
- Create: `mepagueoque_api/test/mepagueoque_api/workers/expiration_sweeper_test.exs`
- Modify: `mepagueoque_api/lib/mepagueoque_api/application.ex`

**Step 1 — Write test**

```elixir
defmodule MepagueoqueApi.Workers.ExpirationSweeperTest do
  use MepagueoqueApi.DataCase, async: true
  alias MepagueoqueApi.Workers.ExpirationSweeper
  alias MepagueoqueApi.Schemas.PaymentLink

  test "deletes expired rows, keeps fresh ones" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    past = DateTime.add(now, -10, :second)
    future = DateTime.add(now, 86_400, :second)

    {:ok, _expired} = insert(:expired, %{slug: "expired-row", expires_at: past})
    {:ok, _alive} = insert(:alive, %{slug: "alive-row", expires_at: future})

    deleted = ExpirationSweeper.sweep()
    assert deleted == 1

    assert Repo.get_by(PaymentLink, slug: "alive-row")
    refute Repo.get_by(PaymentLink, slug: "expired-row")
  end

  defp insert(_kind, overrides) do
    attrs = %{
      slug: "x",
      pix_key: "iago@example.com",
      pix_key_type: "email",
      beneficiary_name: "IAGO",
      city: "BELEM",
      description: "VOLEI",
      amount_cents: 1500,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      expires_at: DateTime.utc_now() |> DateTime.add(86_400, :second) |> DateTime.truncate(:second)
    }

    %PaymentLink{}
    |> Ecto.Changeset.change(Map.merge(attrs, overrides))
    |> Repo.insert()
  end
end
```

**Step 2 — Implement sweeper**

```elixir
defmodule MepagueoqueApi.Workers.ExpirationSweeper do
  @moduledoc "Periodic task that deletes expired payment_links rows."

  use GenServer
  require Logger
  import Ecto.Query
  alias MepagueoqueApi.{Repo, Schemas.PaymentLink}

  @interval :timer.hours(6)

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    schedule()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:sweep, state) do
    sweep()
    schedule()
    {:noreply, state}
  end

  @spec sweep() :: integer()
  def sweep do
    now = DateTime.utc_now()
    {count, _} = Repo.delete_all(from p in PaymentLink, where: p.expires_at < ^now)
    if count > 0, do: Logger.info("ExpirationSweeper: deleted #{count} expired payment_links")
    count
  end

  defp schedule, do: Process.send_after(self(), :sweep, @interval)
end
```

**Step 3 — Add to supervision tree**

In `application.ex`:
```elixir
children = [
  MepagueoqueApi.Repo,
  MepagueoqueApi.Workers.ExpirationSweeper,
  {Bandit, plug: MepagueoqueApi.Router, port: port, scheme: :http, ip: {0, 0, 0, 0}}
]
```

**Step 4 — Run tests**

```bash
mix test
```
Expected: all pass.

**Step 5 — Commit**

```bash
git add lib/mepagueoque_api/workers/expiration_sweeper.ex test/ lib/mepagueoque_api/application.ex
git commit -m "feat: ExpirationSweeper deletes payment_links every 6h"
```

---

## Task 11: Release migrate + Dockerfile + Fly volume

**Files:**
- Create: `mepagueoque_api/lib/mepagueoque_api/release.ex`
- Modify: `mepagueoque_api/Dockerfile`
- Modify: `mepagueoque_api/fly.toml`

**Step 1 — `Release.migrate/0`**

```elixir
defmodule MepagueoqueApi.Release do
  @moduledoc "Release-time helpers (migrations)."

  @app :mepagueoque_api

  def migrate do
    load_app()
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  defp repos, do: Application.fetch_env!(@app, :ecto_repos)

  defp load_app do
    Application.load(@app)
  end
end
```

**Step 2 — Dockerfile changes**

Add this near the end of the runtime stage (before `CMD`):
```dockerfile
# Copy priv (migrations) into release
COPY --from=build --chown=app:app /app/_build/prod/rel/mepagueoque_api/lib /home/app/lib

# Run migrations on boot via entrypoint
COPY --chown=app:app docker/entrypoint.sh /home/app/entrypoint.sh
RUN chmod +x /home/app/entrypoint.sh
CMD ["/home/app/entrypoint.sh"]
```

Then create `mepagueoque_api/docker/entrypoint.sh`:
```bash
#!/bin/sh
set -e
/home/app/bin/mepagueoque_api eval "MepagueoqueApi.Release.migrate()"
exec /home/app/bin/mepagueoque_api start
```

**Step 3 — fly.toml volume mount**

Append:
```toml
[[mounts]]
  source = "mepagueoque_data"
  destination = "/data"
```

And set the env var:
```toml
[env]
  PORT = '8080'
  MIX_ENV = 'prod'
  DATABASE_PATH = '/data/mepagueoque.db'
```

**Step 4 — Manual deploy steps (do not run from this plan)**

Document in commit message:
```bash
# One-time:
flyctl volumes create mepagueoque_data --region gru --size 1

# Then deploy:
flyctl deploy
```

**Step 5 — Commit**

```bash
git add lib/mepagueoque_api/release.ex Dockerfile docker/entrypoint.sh fly.toml
git commit -m "chore: release-time migrations + Fly volume mount for SQLite"
```

---

# Phase 3 — Frontend

## Task 12: Add vue-router + qrcode deps

**Files:**
- Modify: `package.json`

**Step 1 — Install**

```bash
yarn add vue-router@^4.4.0 qrcode@^1.5.4
```

**Step 2 — Verify build still works**

```bash
yarn build
```
Expected: clean build.

**Step 3 — Commit**

```bash
git add package.json yarn.lock
git commit -m "chore: add vue-router and qrcode deps"
```

---

## Task 13: Set up router + refactor App.vue

**Files:**
- Create: `src/router/index.js`
- Modify: `src/main.js`
- Modify: `src/App.vue`

**Step 1 — Create router**

`src/router/index.js`:
```javascript
import { createRouter, createWebHistory } from 'vue-router'
import Home from '@/components/Index.vue'

const routes = [
  { path: '/', name: 'home', component: Home },
  {
    path: '/criar',
    name: 'create-payment',
    component: () => import('@/components/CreatePaymentPage.vue'),
  },
  {
    path: '/p/:slug',
    name: 'payment',
    component: () => import('@/components/PaymentPage.vue'),
    props: true,
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

export const router = createRouter({
  history: createWebHistory(),
  routes,
})
```

**Step 2 — Wire in main.js**

Add to `src/main.js`:
```javascript
import { router } from './router'
// ... existing
app.use(router)
```

**Step 3 — Refactor App.vue**

Replace `<Index />` with `<router-view />`. Move the hero/content/footer chrome to a layout pattern — simplest: keep Content and Footer always, swap only the hero region.

```html
<template>
  <v-app>
    <v-main class="hero-section">
      <router-view />
    </v-main>
    <v-main class="content-section">
      <Content />
    </v-main>
    <Footer />
  </v-app>
</template>

<script>
import Content from './components/Content.vue'
import Footer from './components/Footer.vue'

export default {
  name: 'App',
  components: { Content, Footer },
}
</script>
```

**Step 4 — Verify**

```bash
yarn dev
```
Visit `http://localhost:5173/` — homepage still works.
Visit `/criar` — should show "not found" placeholder (component doesn't exist yet, will lazy-load fail; that's expected at this point — skip to Task 14).

```bash
yarn test --run
```
Expected: existing 18 tests still pass (Index/Content/Footer specs unchanged).

**Step 5 — Commit**

```bash
git add src/main.js src/App.vue src/router/index.js
git commit -m "feat: add vue-router with home route"
```

---

## Task 14: `CreatePaymentPage.vue`

**Files:**
- Create: `src/components/CreatePaymentPage.vue`
- Create: `src/components/CreatePaymentPage.spec.js`

**Step 1 — Write failing test**

`src/components/CreatePaymentPage.spec.js`:
```javascript
import { mount } from '@vue/test-utils'
import { describe, it, expect, vi } from 'vitest'
import { createVuetify } from 'vuetify'
import { createRouter, createWebHistory } from 'vue-router'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import axios from 'axios'
import CreatePaymentPage from './CreatePaymentPage.vue'

vi.mock('axios')

const buildVuetify = () => createVuetify({ components, directives })
const buildRouter = () =>
  createRouter({ history: createWebHistory(), routes: [{ path: '/p/:slug', name: 'payment', component: { template: '<div>p</div>' } }] })

describe('CreatePaymentPage', () => {
  it('submits form and redirects to /p/:slug on success', async () => {
    axios.post.mockResolvedValue({ data: { slug: 'volei', url: 'https://mepagueoque.dev/p/volei' } })

    const router = buildRouter()
    const push = vi.spyOn(router, 'push')

    const wrapper = mount(CreatePaymentPage, {
      global: { plugins: [buildVuetify(), router] },
    })

    await wrapper.find('[data-test="pix-key"]').setValue('iago@example.com')
    await wrapper.find('[data-test="beneficiary-name"]').setValue('IAGO')
    await wrapper.find('[data-test="city"]').setValue('BELEM')
    await wrapper.find('[data-test="description"]').setValue('VOLEI')
    await wrapper.find('[data-test="amount"]').setValue('15.00')
    // Turnstile token is set via prop or refs; in test we cheat:
    wrapper.vm.turnstileToken = 'bypass'

    await wrapper.find('[data-test="submit"]').trigger('click')
    await new Promise(r => setTimeout(r, 50))

    expect(axios.post).toHaveBeenCalled()
    expect(push).toHaveBeenCalledWith({ name: 'payment', params: { slug: 'volei' } })
  })

  it('shows inline error on 409 slug_taken', async () => {
    axios.post.mockRejectedValue({ response: { status: 409, data: { error: 'slug_taken' } } })

    const wrapper = mount(CreatePaymentPage, {
      global: { plugins: [buildVuetify(), buildRouter()] },
    })

    await wrapper.find('[data-test="pix-key"]').setValue('iago@example.com')
    await wrapper.find('[data-test="beneficiary-name"]').setValue('IAGO')
    await wrapper.find('[data-test="city"]').setValue('BELEM')
    await wrapper.find('[data-test="description"]').setValue('VOLEI')
    await wrapper.find('[data-test="amount"]').setValue('15.00')
    await wrapper.find('[data-test="slug"]').setValue('dup')
    wrapper.vm.turnstileToken = 'bypass'

    await wrapper.find('[data-test="submit"]').trigger('click')
    await new Promise(r => setTimeout(r, 50))

    expect(wrapper.text()).toContain('esse slug já existe')
  })
})
```

**Step 2 — Implement component**

`src/components/CreatePaymentPage.vue` — Composition API, Vuetify form with the 6 fields, BRL amount mask via simple input event, Turnstile widget (reuse `vue-turnstile`), submit handler posts to `${VITE_API_HOST}/pagamentos`.

```vue
<template>
  <v-container class="py-12" max-width="600">
    <h1 class="text-h4 mb-6">Criar link de cobrança PIX</h1>

    <v-form @submit.prevent="submit" :disabled="loading">
      <v-text-field
        v-model="form.pix_key"
        label="Sua chave PIX"
        placeholder="email, CPF, CNPJ, telefone ou chave aleatória"
        data-test="pix-key"
        required
      />
      <v-text-field
        v-model="form.beneficiary_name"
        label="Seu nome (máx 25)"
        maxlength="25"
        data-test="beneficiary-name"
        required
      />
      <v-text-field
        v-model="form.city"
        label="Cidade (máx 15)"
        maxlength="15"
        placeholder="BRASIL"
        data-test="city"
      />
      <v-text-field
        v-model="form.description"
        label="Descrição (máx 72)"
        maxlength="72"
        data-test="description"
        required
      />
      <v-text-field
        v-model="form.amount"
        label="Valor (R$)"
        type="number"
        step="0.01"
        min="0.01"
        data-test="amount"
        required
      />
      <v-text-field
        v-model="form.slug"
        label="Slug personalizado (opcional)"
        hint="deixe em branco pra gerar automaticamente"
        persistent-hint
        data-test="slug"
      />

      <vue-turnstile
        :site-key="siteKey"
        v-model="turnstileToken"
        class="my-4"
      />

      <v-alert v-if="error" type="error" class="my-3">{{ error }}</v-alert>

      <v-btn
        color="primary"
        type="submit"
        :loading="loading"
        :disabled="!turnstileToken"
        data-test="submit"
        block
      >
        Gerar link
      </v-btn>
    </v-form>
  </v-container>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import VueTurnstile from 'vue-turnstile'

const router = useRouter()
const siteKey = import.meta.env.VITE_TURNSTILE_SITE_KEY
const apiHost = import.meta.env.VITE_API_HOST || import.meta.env.VITE_LAMBDA_HOST?.replace('/enviar-cobranca', '')

const form = reactive({
  pix_key: '',
  beneficiary_name: '',
  city: '',
  description: '',
  amount: '',
  slug: '',
})

const turnstileToken = ref('')
const loading = ref(false)
const error = ref('')

const submit = async () => {
  error.value = ''
  loading.value = true

  const payload = {
    pix_key: form.pix_key,
    beneficiary_name: form.beneficiary_name,
    city: form.city || 'BRASIL',
    description: form.description,
    amount_cents: Math.round(parseFloat(form.amount) * 100),
    slug: form.slug || undefined,
    token: turnstileToken.value,
  }

  try {
    const { data } = await axios.post(`${apiHost}/pagamentos`, payload)
    router.push({ name: 'payment', params: { slug: data.slug } })
  } catch (e) {
    if (e?.response?.status === 409) {
      error.value = 'esse slug já existe, escolhe outro'
    } else if (e?.response?.status === 400) {
      error.value = 'algum campo está inválido — confere os dados'
    } else if (e?.response?.status === 401) {
      error.value = 'verificação anti-bot falhou, recarrega a página'
    } else {
      error.value = 'algo deu errado, tenta de novo'
    }
  } finally {
    loading.value = false
  }
}

defineExpose({ turnstileToken })
</script>
```

**Step 3 — Run tests**

```bash
yarn test --run src/components/CreatePaymentPage.spec.js
```
Expected: 2 tests pass.

**Step 4 — Commit**

```bash
git add src/components/CreatePaymentPage.vue src/components/CreatePaymentPage.spec.js
git commit -m "feat: CreatePaymentPage with Turnstile + redirect"
```

---

## Task 15: `PaymentPage.vue`

**Files:**
- Create: `src/components/PaymentPage.vue`
- Create: `src/components/PaymentPage.spec.js`

**Step 1 — Write failing test**

```javascript
import { mount, flushPromises } from '@vue/test-utils'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import axios from 'axios'
import PaymentPage from './PaymentPage.vue'

vi.mock('axios')
vi.mock('qrcode', () => ({ default: { toCanvas: vi.fn() } }))

const buildVuetify = () => createVuetify({ components, directives })

describe('PaymentPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders payload after fetch', async () => {
    axios.get.mockResolvedValue({
      data: {
        slug: 'volei',
        beneficiary_name: 'IAGO',
        description: 'VOLEI 18/05',
        amount_cents: 1500,
        br_code: '00020126...',
        expires_at: new Date(Date.now() + 86400000).toISOString(),
      },
    })

    const wrapper = mount(PaymentPage, {
      props: { slug: 'volei' },
      global: { plugins: [buildVuetify()] },
    })

    await flushPromises()

    expect(wrapper.text()).toContain('IAGO')
    expect(wrapper.text()).toContain('VOLEI 18/05')
    expect(wrapper.text()).toContain('R$ 15,00')
    expect(wrapper.find('[data-test="br-code"]').text()).toBe('00020126...')
  })

  it('shows expired state on 404', async () => {
    axios.get.mockRejectedValue({ response: { status: 404 } })

    const wrapper = mount(PaymentPage, {
      props: { slug: 'gone' },
      global: { plugins: [buildVuetify()] },
    })

    await flushPromises()
    expect(wrapper.text()).toContain('Esse link expirou ou não existe')
  })
})
```

**Step 2 — Implement**

```vue
<template>
  <v-container class="py-12" max-width="500">
    <v-progress-circular v-if="loading" indeterminate class="d-block mx-auto my-8" />

    <div v-else-if="notFound" class="text-center">
      <h1 class="text-h5 mb-4">Esse link expirou ou não existe</h1>
      <v-btn :to="{ name: 'create-payment' }" color="primary">Criar um novo</v-btn>
    </div>

    <div v-else-if="data">
      <h1 class="text-h4 mb-2">{{ formatBRL(data.amount_cents) }}</h1>
      <p class="text-subtitle-1 mb-2">para <strong>{{ data.beneficiary_name }}</strong></p>
      <p class="text-body-2 mb-6">{{ data.description }}</p>

      <canvas ref="qrCanvas" class="d-block mx-auto mb-6" />

      <v-textarea
        :model-value="data.br_code"
        readonly
        auto-grow
        rows="3"
        data-test="br-code"
        class="mb-2"
      />

      <v-btn block color="primary" @click="copy" class="mb-2">
        {{ copied ? 'Copiado ✓' : 'Copiar código PIX' }}
      </v-btn>
      <v-btn block variant="outlined" @click="share">Compartilhar link</v-btn>

      <p class="text-caption text-center mt-6">
        Expira em {{ formatDate(data.expires_at) }}
      </p>
    </div>
  </v-container>
</template>

<script setup>
import { ref, onMounted, watch, nextTick } from 'vue'
import axios from 'axios'
import QRCode from 'qrcode'

const props = defineProps({ slug: { type: String, required: true } })
const apiHost = import.meta.env.VITE_API_HOST || import.meta.env.VITE_LAMBDA_HOST?.replace('/enviar-cobranca', '')

const loading = ref(true)
const notFound = ref(false)
const data = ref(null)
const copied = ref(false)
const qrCanvas = ref(null)

onMounted(async () => {
  try {
    const res = await axios.get(`${apiHost}/pagamentos/${props.slug}`)
    data.value = res.data
    await nextTick()
    if (qrCanvas.value) await QRCode.toCanvas(qrCanvas.value, res.data.br_code, { width: 280 })
  } catch (e) {
    if (e?.response?.status === 404) notFound.value = true
    else notFound.value = true
  } finally {
    loading.value = false
  }
})

const copy = async () => {
  if (!data.value) return
  await navigator.clipboard.writeText(data.value.br_code)
  copied.value = true
  setTimeout(() => (copied.value = false), 2000)
}

const share = async () => {
  const url = window.location.href
  if (navigator.share) {
    try { await navigator.share({ url }) } catch {}
  } else {
    await navigator.clipboard.writeText(url)
  }
}

const formatBRL = (cents) =>
  new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(cents / 100)

const formatDate = (iso) =>
  new Date(iso).toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' })
</script>
```

**Step 3 — Run tests**

```bash
yarn test --run src/components/PaymentPage.spec.js
```
Expected: 2 tests pass.

**Step 4 — Manual smoke test**

```bash
yarn dev
# Visit /criar, fill form, submit → redirected to /p/<slug>, QR renders, "Copiar" works
```

**Step 5 — Commit**

```bash
git add src/components/PaymentPage.vue src/components/PaymentPage.spec.js
git commit -m "feat: PaymentPage with QR rendering + copy-to-clipboard"
```

---

## Task 16: Env var setup

**Files:**
- Modify: `.env.example` (create if missing)

**Step 1 — Document new var**

Add to `.env.example`:
```
VITE_API_HOST=https://mepagueoque-api.fly.dev
```

**Step 2 — Update README**

Add a short section under "Frontend" listing `VITE_API_HOST` as required.

**Step 3 — Commit**

```bash
git add .env.example README.md
git commit -m "docs: VITE_API_HOST env var for new payment links"
```

---

# Phase 4 — Wire-up & polish

## Task 17: Add `/criar` entry from homepage

**Files:**
- Modify: `src/components/Index.vue` (the existing home form)

**Step 1 — Add a small CTA**

Below the existing email/WhatsApp form, add:
```html
<router-link to="/criar" class="text-body-2 d-block text-center mt-4">
  ou crie um link de cobrança compartilhável (PIX) →
</router-link>
```

**Step 2 — Verify**

```bash
yarn dev
```
Click the link → lands on `/criar`.

**Step 3 — Commit**

```bash
git add src/components/Index.vue
git commit -m "feat: CTA from homepage to /criar"
```

---

## Task 18: End-to-end smoke test + PR

**Step 1 — Full suite**

```bash
yarn test --run
mix test
yarn build
```
All green.

**Step 2 — Manual e2e**

1. `mix phx.server` (backend, port 4000)
2. `yarn dev` (frontend, port 5173)
3. Visit `/criar`, fill form with real PIX key, generate.
4. Open resulting `/p/<slug>` on mobile, scan QR in your bank app, verify payment screen shows correct amount + beneficiary.
5. Copy "copia e cola" string, paste in bank app, verify same.
6. Hit a non-existent `/p/nope` → see "Esse link expirou ou não existe".

**Step 3 — Open PR**

```bash
git push -u origin feature/pix-payment-links
gh pr create --title "feat: PIX shareable payment links (/p/{slug})" --body "$(cat <<'EOF'
## Summary
- Adds /criar form + /p/{slug} pages with QR + copy-paste BR Code
- Persists in SQLite on a new Fly volume
- 90-day TTL, swept by a background GenServer
- Reuses existing Turnstile integration

## Test plan
- [x] mix test (full backend suite)
- [x] yarn test (full frontend suite)
- [x] Manual: fill /criar, generate, scan QR in bank app, payment goes through
- [x] Manual: copy "copia e cola" string, paste in bank app, works
- [x] Manual: visit /p/nope → 404 state renders

See design at docs/plans/2026-05-14-pix-payment-links-design.md.
EOF
)"
```

---

# Done criteria

- [ ] All tasks 1–18 committed on `feature/pix-payment-links`.
- [ ] `mix test` and `yarn test --run` both green.
- [ ] One successful real PIX payment scanned from a generated `/p/{slug}` page.
- [ ] Fly volume created, deploy succeeds, prod DB migrated.
- [ ] PR opened with the checklist above.
