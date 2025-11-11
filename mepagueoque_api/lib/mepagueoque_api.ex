defmodule MepagueoqueApi do
  @moduledoc """
  MePagueOQue API - Payment Reminder Service.

  A fun and subtle way to remind people to pay their debts via email.
  This API integrates with multiple third-party services to provide a complete
  payment reminder experience with GIFs and bot protection.

  ## Overview

  The API provides a single endpoint for sending payment reminders:
    - `/enviar-cobranca` (POST) - Sends a payment reminder email

  ## Architecture

  The application follows OTP principles and is organized into several layers:

  ### Routing Layer
    - `MepagueoqueApi.Router` - HTTP request routing and response handling

  ### Controller Layer
    - `MepagueoqueApi.Controllers.PaymentReminderController` - Business logic orchestration

  ### Service Layer
    - `MepagueoqueApi.Services.Turnstile` - Bot detection with Cloudflare Turnstile
    - `MepagueoqueApi.Services.Giphy` - Random GIF fetching from Giphy
    - `MepagueoqueApi.Services.Resend` - Email sending via Resend

  ### Schema Layer
    - `MepagueoqueApi.Schemas.PaymentReminder` - Request validation and sanitization
    - `MepagueoqueApi.Schemas.GifData` - GIF metadata structure

  ### Infrastructure
    - `MepagueoqueApi.Application` - OTP application supervision tree
    - `MepagueoqueApi.HTTPClient` - HTTP client with retry logic

  ## Integration Services

  ### Cloudflare Turnstile
  Provides bot detection and CAPTCHA verification without user interaction.
  Requires `TURNSTILE_SECRET_KEY` environment variable.

  ### Giphy API
  Fetches random money-themed GIFs to make payment reminders more engaging.
  Requires `GIPHY_API_KEY` environment variable.

  ### Resend
  Modern email delivery service for sending transactional emails.
  Requires `RESEND_API_KEY` and `FROM_EMAIL` environment variables.

  ## Configuration

  Required environment variables:
    - `PORT` - HTTP server port (default: 4000)
    - `TURNSTILE_SECRET_KEY` - Cloudflare Turnstile secret key
    - `GIPHY_API_KEY` - Giphy API key
    - `GIPHY_URL` - Giphy API base URL (optional, defaults to official URL)
    - `RESEND_API_KEY` - Resend API key
    - `FROM_EMAIL` - Sender email address (must be verified in Resend)

  ## Deployment

  The application is designed for easy deployment:

  ### Development
  ```bash
  mix deps.get
  mix run --no-halt
  ```

  ### Production (OTP Release)
  ```bash
  MIX_ENV=prod mix release
  _build/prod/rel/mepagueoque_api/bin/mepagueoque_api start
  ```

  ## API Usage Example

  ```bash
  curl -X POST http://localhost:4000/enviar-cobranca \\
    -H "Content-Type: application/json" \\
    -d '{
      "text": "Hey, please pay me for the dinner!",
      "value": "50.00",
      "destination": "friend@example.com",
      "token": "cloudflare_turnstile_token"
    }'
  ```

  ## Error Handling

  The API uses Elixir's "let it crash" philosophy with proper supervision.
  All errors are logged and appropriate HTTP status codes are returned:
    - 200 - Success
    - 400 - Invalid request parameters
    - 401 - Token verification failed
    - 500 - Internal server error

  ## Monitoring

  Health check endpoint available at `/health` for load balancers and monitoring.

  ## License

  This project is part of the MePagueOQue.Dev platform.
  """

  @doc false
  def hello do
    :world
  end
end
