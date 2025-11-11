# MePagueOQue API

A professional Elixir API for sending payment reminder emails with GIFs and bot protection.

## Overview

MePagueOQue API is a serverless-ready Elixir application that provides a simple HTTP endpoint for sending payment reminder emails. It integrates with Cloudflare Turnstile for bot protection, Giphy for fun GIFs, and Resend for reliable email delivery.

## Tech Stack

- **Elixir 1.19+** with **Erlang/OTP 27+**
- **Bandit** - High-performance HTTP/1.1 and HTTP/2 server
- **Plug** - Composable modules for web applications
- **Req** - Modern HTTP client with retry logic
- **Resend** - Email delivery service
- **Giphy** - GIF integration
- **Cloudflare Turnstile** - Bot protection (replaced reCAPTCHA)

## Features

- Bot Protection with Cloudflare Turnstile
- Fun money-themed GIFs from Giphy in every email
- Reliable email delivery via Resend API
- Comprehensive input validation and sanitization
- Proper error handling with detailed logging
- Built-in health check endpoint for monitoring
- CORS support for web applications
- Automatic retry with exponential backoff for external APIs
- Full typespec coverage for Dialyzer
- Production-ready OTP releases

## Architecture

The application follows Elixir and OTP best practices:

```
┌─────────────────────────────────────────────────────────────────┐
│                         HTTP Layer                               │
│  MepagueoqueApi.Router - Request routing and HTTP handling      │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                     Controller Layer                             │
│  PaymentReminderController - Business logic orchestration       │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
┌─────────────▼──┐  ┌────────▼────────┐  ┌─▼─────────────┐
│   Turnstile    │  │     Giphy       │  │    Resend     │
│    Service     │  │    Service      │  │   Service     │
└────────────────┘  └─────────────────┘  └───────────────┘
```

## Getting Started

### Prerequisites

- Elixir 1.19+ and Erlang/OTP 27+
- Mix build tool

### Installation

1. **Install dependencies:**

```bash
cd mepagueoque_api
mix deps.get
```

2. **Configure environment variables:**

Create a `.env` file with required environment variables:

```bash
PORT=4000
TURNSTILE_SECRET_KEY=your_turnstile_secret_key
GIPHY_API_KEY=your_giphy_api_key
RESEND_API_KEY=your_resend_api_key
FROM_EMAIL=noreply@yourdomain.com
```

3. **Run the server:**

```bash
mix run --no-halt
```

The API will be available at `http://localhost:4000`

## Configuration

### Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `PORT` | No | HTTP server port | 4000 |
| `TURNSTILE_SECRET_KEY` | Yes | Cloudflare Turnstile secret key | - |
| `GIPHY_API_KEY` | Yes | Giphy API key | - |
| `GIPHY_URL` | No | Giphy API base URL | https://api.giphy.com/v1/gifs |
| `RESEND_API_KEY` | Yes | Resend API key | - |
| `FROM_EMAIL` | Yes | Sender email address (verified in Resend) | - |

## API Endpoints

### POST /enviar-cobranca

Sends a payment reminder email.

**Request Body:**
```json
{
  "text": "Hey, please pay me for the dinner!",
  "value": "50.00",
  "destination": "friend@example.com",
  "token": "cloudflare_turnstile_token"
}
```

**Response (200 OK):**
```json
{
  "message": "Email enviado com sucesso, consagrado(a)!",
  "success": true
}
```

**Error Responses:**

- **400 Bad Request**: Invalid parameters
```json
{
  "error": "Parâmetros inválidos",
  "details": ["text is required", "value cannot be empty"]
}
```

- **401 Unauthorized**: Turnstile verification failed
```json
{
  "error": "Verificação falhou",
  "details": "Response token is invalid or has expired"
}
```

- **500 Internal Server Error**: Server error
```json
{
  "error": "Erro ao processar cobrança",
  "details": "Email service error"
}
```

### GET /health

Health check endpoint for monitoring.

**Response (200 OK):**
```json
{
  "status": "ok",
  "service": "mepagueoque-api"
}
```

## Project Structure

```
mepagueoque_api/
├── config/
│   ├── config.exs          # Base configuration
│   ├── dev.exs             # Development config
│   ├── prod.exs            # Production config
│   ├── test.exs            # Test config
│   └── runtime.exs         # Runtime configuration
├── lib/
│   └── mepagueoque_api/
│       ├── application.ex  # OTP application
│       ├── router.ex       # HTTP router
│       ├── http_client.ex  # HTTP client wrapper
│       ├── controllers/
│       │   └── payment_reminder_controller.ex
│       ├── schemas/
│       │   ├── payment_reminder.ex
│       │   └── gif_data.ex
│       └── services/
│           ├── turnstile.ex
│           ├── giphy.ex
│           └── resend.ex
├── test/
│   └── mepagueoque_api/
│       └── schemas/
│           ├── payment_reminder_test.exs
│           └── gif_data_test.exs
├── mix.exs                 # Project configuration
└── README.md
```

## Development

### Running Tests

```bash
mix test
```

### Code Formatting

```bash
mix format
```

### Type Checking with Dialyzer

Add dialyxir to your dependencies and run:

```bash
mix dialyzer
```

### Generating Documentation

```bash
mix docs
```

## Production Deployment

### Building an OTP Release

```bash
MIX_ENV=prod mix release
```

### Running the Release

```bash
PORT=4000 \
TURNSTILE_SECRET_KEY=xxx \
GIPHY_API_KEY=xxx \
RESEND_API_KEY=xxx \
FROM_EMAIL=noreply@yourdomain.com \
_build/prod/rel/mepagueoque_api/bin/mepagueoque_api start
```

## Security

- Input validation and sanitization
- Bot protection via Cloudflare Turnstile
- Email format validation
- HTML escaping for user input
- HTTPS recommended for production

## License

See the main project LICENSE file.

