defmodule MepagueoqueApi.Router do
  @moduledoc """
  HTTP Router for MePagueOQue API.

  This module defines the HTTP endpoints and routes requests to appropriate controllers.
  It handles CORS, request parsing, and error handling at the HTTP layer.
  """

  use Plug.Router
  use Plug.ErrorHandler

  alias MepagueoqueApi.Controllers.PaymentLinkController
  alias MepagueoqueApi.Controllers.PaymentReminderController

  require Logger

  # Plugs
  plug(CORSPlug,
    origin: &__MODULE__.get_allowed_origins/0,
    headers: ["content-type", "authorization"],
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  )

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  # Get allowed CORS origins from configuration
  def get_allowed_origins do
    Application.get_env(:mepagueoque_api, :allowed_origins, [
      "http://localhost:8080",
      "https://mepagueoque.dev"
    ])
  end

  # Health check endpoint for monitoring and load balancers.
  # Returns a simple JSON response indicating the service is running.
  get "/health" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", service: "mepagueoque-api"}))
  end

  # Handle OPTIONS preflight request for CORS
  options "/enviar-cobranca" do
    conn
    |> send_resp(200, "")
  end

  # Main endpoint for sending payment reminders.
  #
  # Accepts POST requests with payment reminder data and processes them through
  # the PaymentReminderController.
  #
  # Request Body:
  #   - text: Message to include in the reminder
  #   - value: Amount being charged
  #   - destination: Recipient email address
  #   - token: Cloudflare Turnstile verification token
  #
  # Responses:
  #   - 200: Email sent successfully
  #   - 400: Invalid request parameters
  #   - 401: Token verification failed
  #   - 500: Internal server error
  post "/enviar-cobranca" do
    case parse_body(conn) do
      {:ok, params} ->
        handle_payment_reminder(conn, params)

      {:error, reason} ->
        Logger.warning("Failed to parse request body: #{inspect(reason)}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "Invalid request body", details: reason}))
    end
  end

  # Handle OPTIONS preflight request for CORS on the payment links endpoint.
  options "/pagamentos" do
    send_resp(conn, 200, "")
  end

  # Create a PIX payment link.
  #
  # Request Body:
  #   - pix_key: PIX key (email, CPF, CNPJ, phone, or random key)
  #   - beneficiary_name: Beneficiary name (up to 25 chars)
  #   - city: Beneficiary city (up to 15 chars)
  #   - description: Description shown to the payer
  #   - amount_cents: Amount in cents
  #   - slug: Optional desired slug (auto-generated otherwise)
  #   - token: Cloudflare Turnstile verification token
  #
  # Responses:
  #   - 200: Link created (returns slug, br_code, expires_at, url)
  #   - 400: Invalid request parameters
  #   - 401: Token verification failed
  #   - 409: Slug already taken
  #   - 500: Internal server error
  post "/pagamentos" do
    case parse_body(conn) do
      {:ok, params} ->
        handle_create_payment(conn, params)

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: reason}))
    end
  end

  # Fetch a PIX payment link by slug.
  #
  # Responses:
  #   - 200: Returns slug, beneficiary_name, description, amount_cents, br_code, expires_at
  #   - 404: Slug not found or link expired
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

  # Fallback route for unmatched endpoints.
  # Returns a 404 Not Found response for any route that doesn't match defined endpoints.
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "Not found"}))
  end

  # Error handler for unexpected exceptions during request processing.
  # Logs the error details and returns a generic 500 Internal Server Error response.
  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    Logger.error("""
    Request error:
    Kind: #{inspect(kind)}
    Reason: #{inspect(reason)}
    Stack: #{inspect(stack)}
    """)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(500, Jason.encode!(%{error: "Internal server error"}))
  end

  # Private functions

  @spec parse_body(Plug.Conn.t()) :: {:ok, map()} | {:error, String.t()}
  defp parse_body(%Plug.Conn{body_params: %Plug.Conn.Unfetched{}}),
    do: {:error, "No body provided"}

  defp parse_body(%Plug.Conn{body_params: params}) when is_map(params), do: {:ok, params}
  defp parse_body(_), do: {:error, "Invalid body format"}

  @spec handle_payment_reminder(Plug.Conn.t(), map()) :: Plug.Conn.t()
  defp handle_payment_reminder(conn, params) do
    # Pass conn to controller for IP extraction
    case PaymentReminderController.process(conn, params) do
      {:ok, response} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(response))

      {:error, :invalid_params, errors} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "Parâmetros inválidos", details: errors}))

      {:error, :turnstile_verification_failed, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Verificação falhou", details: reason}))

      {:error, _type, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{error: "Erro ao processar cobrança", details: reason}))
    end
  end

  @spec handle_create_payment(Plug.Conn.t(), map()) :: Plug.Conn.t()
  defp handle_create_payment(conn, params) do
    case PaymentLinkController.create(conn, params) do
      {:ok, payload} ->
        body = Map.put(payload, :url, "https://mepagueoque.dev/p/#{payload.slug}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(body))

      {:error, :invalid_params, errors} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "invalid_params", details: errors}))

      {:error, :slug_taken} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(409, Jason.encode!(%{error: "slug_taken"}))

      {:error, :turnstile_verification_failed, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "turnstile_failed", details: reason}))

      {:error, _type, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{error: "internal_error", details: reason}))
    end
  end
end
