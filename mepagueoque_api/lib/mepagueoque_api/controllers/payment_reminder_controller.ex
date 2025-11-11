defmodule MepagueoqueApi.Controllers.PaymentReminderController do
  @moduledoc """
  Controller for handling payment reminder requests.

  This module contains the business logic for processing payment reminder requests,
  coordinating between validation, token verification, GIF fetching, and email sending.
  """

  require Logger

  alias MepagueoqueApi.Schemas.PaymentReminder
  alias MepagueoqueApi.Services.{Turnstile, Giphy, Resend}

  @type result :: {:ok, map()} | {:error, atom(), String.t() | [String.t()]}

  @doc """
  Processes a payment reminder request.

  This function orchestrates the entire flow:
  1. Validates the request parameters
  2. Verifies the Turnstile token with client IP
  3. Fetches a random money GIF from Giphy
  4. Sends the payment reminder email via Resend

  ## Parameters
    - conn: Plug connection (for extracting client IP)
    - params: Map containing the payment reminder request data

  ## Returns
    - {:ok, message} if the email was sent successfully
    - {:error, reason, details} if any step fails

  ## Examples

      iex> PaymentReminderController.process(conn, %{"text" => "Pay me!", "value" => "100", "destination" => "test@example.com", "token" => "valid_token"})
      {:ok, %{message: "Email enviado com sucesso, consagrado(a)!", success: true}}
  """
  @spec process(Plug.Conn.t(), map()) :: result()
  def process(conn, params) when is_map(params) do
    Logger.info("Processing payment reminder request")

    # Extract client IP address for Turnstile verification
    client_ip = get_client_ip(conn)

    with {:ok, reminder} <- PaymentReminder.new(params),
         {:ok, _token_data} <- verify_turnstile(reminder, client_ip),
         {:ok, gif_data} <- fetch_gif(),
         {:ok, _email_data} <- send_reminder_email(reminder, gif_data) do
      Logger.info("Payment reminder processed successfully for: #{reminder.destination}")

      {:ok,
       %{
         message: "Email enviado com sucesso, consagrado(a)!",
         success: true
       }}
    else
      {:error, :invalid_params, errors} ->
        Logger.warning("Invalid parameters: #{inspect(errors)}")
        {:error, :invalid_params, errors}

      {:error, :turnstile_verification_failed, reason} ->
        Logger.warning("Turnstile verification failed: #{reason}")
        {:error, :turnstile_verification_failed, reason}

      {:error, :gif_fetch_failed, reason} ->
        Logger.error("Failed to fetch GIF: #{reason}")
        {:error, :gif_fetch_failed, reason}

      {:error, :email_send_failed, reason} ->
        Logger.error("Failed to send email: #{reason}")
        {:error, :email_send_failed, reason}

      {:error, reason} ->
        Logger.error("Unexpected error processing payment reminder: #{inspect(reason)}")
        {:error, :internal_error, "Erro ao processar cobrança"}
    end
  end

  @spec verify_turnstile(PaymentReminder.t(), String.t() | nil) ::
          {:ok, map()} | {:error, :turnstile_verification_failed, String.t()}
  defp verify_turnstile(%PaymentReminder{token: token}, client_ip) do
    Logger.info("Verifying Turnstile with client IP: #{inspect(client_ip)}")

    case Turnstile.verify(token, client_ip) do
      {:ok, data} ->
        Logger.info("Turnstile verification successful: #{inspect(data)}")
        {:ok, data}

      {:error, reason} ->
        Logger.error("Turnstile verification failed - IP: #{inspect(client_ip)}, Reason: #{inspect(reason)}")
        {:error, :turnstile_verification_failed, reason}
    end
  end

  @spec get_client_ip(Plug.Conn.t()) :: String.t() | nil
  defp get_client_ip(conn) do
    # Try to get the real IP from various headers (proxy/CDN aware)
    cond do
      # Fly.io header (priority for Fly.io deployments)
      fly_ip = Plug.Conn.get_req_header(conn, "fly-client-ip") |> List.first() ->
        Logger.info("Client IP from Fly-Client-IP: #{fly_ip}")
        fly_ip

      # Cloudflare header
      cf_ip = Plug.Conn.get_req_header(conn, "cf-connecting-ip") |> List.first() ->
        Logger.info("Client IP from CF-Connecting-IP: #{cf_ip}")
        cf_ip

      # Standard forwarded-for header
      forwarded = Plug.Conn.get_req_header(conn, "x-forwarded-for") |> List.first() ->
        # Take first IP in the chain
        ip = forwarded |> String.split(",") |> List.first() |> String.trim()
        Logger.info("Client IP from X-Forwarded-For: #{ip}")
        ip

      # Real IP header
      real_ip = Plug.Conn.get_req_header(conn, "x-real-ip") |> List.first() ->
        Logger.info("Client IP from X-Real-IP: #{real_ip}")
        real_ip

      # Fallback to remote IP from connection
      true ->
        case conn.remote_ip do
          {a, b, c, d} ->
            ip = "#{a}.#{b}.#{c}.#{d}"
            Logger.info("Client IP from remote_ip: #{ip}")
            ip

          _ ->
            Logger.warning("Could not extract client IP")
            nil
        end
    end
  end

  @spec fetch_gif() :: {:ok, map()} | {:error, :gif_fetch_failed, String.t()}
  defp fetch_gif do
    case Giphy.fetch_random_money_gif() do
      {:ok, gif_data} ->
        {:ok, gif_data}

      {:error, reason} ->
        {:error, :gif_fetch_failed, reason}
    end
  end

  @spec send_reminder_email(PaymentReminder.t(), map()) ::
          {:ok, map()} | {:error, :email_send_failed, String.t()}
  defp send_reminder_email(%PaymentReminder{} = reminder, gif_data) do
    html = Resend.build_email_html(reminder.text, reminder.value, gif_data)
    subject = "Olá, Me pague o que dev."

    case Resend.send_email(reminder.destination, subject, html) do
      {:ok, data} ->
        {:ok, data}

      {:error, reason} ->
        {:error, :email_send_failed, reason}
    end
  end
end
