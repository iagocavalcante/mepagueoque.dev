#mepagueoque.dev

## Project setup
```
yarn install
```

### Compiles and hot-reloads for development
```
yarn serve
```

### Compiles and minifies for production
```
yarn build
```

### Lints and fixes files
```
yarn lint
```

### Customize configuration
See [Configuration Reference](https://cli.vuejs.org/config/).

### Environment variables
Copy `.env.example` to `.env` and fill in the values. Notable variables:

- **`VITE_API_HOST`** — base URL of the Elixir API (e.g. `https://mepagueoque-api.fly.dev`). Required for the `/criar` payment-link form and `/p/:slug` display pages.
- **`VITE_LAMBDA_HOST`** — legacy endpoint used by the email-charge form on the homepage.
- **`VITE_TURNSTILE_SITE_KEY`** — Cloudflare Turnstile site key for bot protection.
