defmodule MepagueoqueApi.Services.Resend do
  @moduledoc """
  Service for sending emails via Resend API.

  Resend is a modern email API service that provides reliable email delivery
  with a developer-friendly interface. This service handles email composition
  and sending through Resend's API.

  ## Configuration

  Required environment variables:
    - RESEND_API_KEY: Your Resend API key
    - FROM_EMAIL: The sender email address (must be verified in Resend)

  ## References
    - [Resend API Documentation](https://resend.com/docs)
  """

  require Logger

  alias MepagueoqueApi.Schemas.GifData

  @resend_api_url "https://api.resend.com/emails"
  @max_message_length 5000
  @max_value_length 50

  @type email_result :: {:ok, map()} | {:error, String.t()}

  @doc """
  Sends a payment reminder email via Resend.

  This function constructs and sends an HTML email with the payment reminder
  message, value, and optional GIF through Resend's API.

  ## Parameters
    - to: Recipient email address
    - subject: Email subject line
    - html: HTML content of the email

  ## Returns
    - `{:ok, response}` containing email ID if successful
    - `{:error, reason}` if sending fails

  ## Examples

      iex> Resend.send_email("user@example.com", "Payment Reminder", "<html>...</html>")
      {:ok, %{"id" => "abc123"}}

      iex> Resend.send_email("invalid", "Subject", "<html>...</html>")
      {:error, "Invalid email format"}

  ## Error Cases
    - Configuration missing: API key or from email not set
    - Invalid email: Recipient email format is invalid
    - Network error: Unable to reach Resend API
    - API error: Resend returned error status
  """
  @spec send_email(String.t(), String.t(), String.t()) :: email_result()
  def send_email(to, subject, html)
      when is_binary(to) and is_binary(subject) and is_binary(html) do
    with {:ok, _api_key} <- get_api_key(),
         {:ok, from_email} <- get_from_email(),
         :ok <- validate_email_format(to),
         {:ok, response} <- send_via_resend(from_email, to, subject, html) do
      {:ok, response}
    end
  end

  def send_email(_to, _subject, _html), do: {:error, "Invalid email parameters"}

  @doc """
  Builds HTML email content with optional GIF.

  Creates a properly formatted HTML email with the payment reminder message,
  value, and an optional money-themed GIF from Giphy.

  ## Parameters
    - message: The user's payment reminder message
    - value: The amount being charged (as string, e.g., "100.00")
    - gif_data: Optional %GifData{} struct from Giphy (default: nil)

  ## Returns
    - HTML string ready to be sent via email

  ## Examples

      iex> Resend.build_email_html("Please pay", "100.00", nil)
      "<div style=...>...</div>"

      iex> gif = %GifData{image_url: "https://...", image_width: "480", image_height: "270"}
      iex> Resend.build_email_html("Please pay", "100.00", gif)
      "<div style=...><img src=...>...</div>"
  """
  @spec build_email_html(String.t(), String.t(), GifData.t() | nil) :: String.t()
  def build_email_html(message, value, gif_data \\ nil)
      when is_binary(message) and is_binary(value) do
    sanitized_message = sanitize_html_content(message, @max_message_length)
    sanitized_value = sanitize_html_content(value, @max_value_length)
    gif_html = build_gif_html(gif_data)

    """
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <h2 style="color: #4CAF50;">Me Pague O Que Dev</h2>

      <div style="margin: 20px 0; padding: 15px; background-color: #f5f5f5; border-radius: 8px;">
        <p style="font-size: 16px; line-height: 1.6; color: #333;">
          #{sanitized_message}
        </p>
      </div>

      #{gif_html}

      <div style="margin: 20px 0; padding: 15px; background-color: #e8f5e9; border-radius: 8px; border-left: 4px solid #4CAF50;">
        <p style="font-size: 18px; font-weight: bold; color: #2e7d32; margin: 0;">
          Valor: R$ #{sanitized_value}
        </p>
      </div>

      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #888;">
        <p>Este email foi enviado através do <strong>MePagueOQue.Dev</strong></p>
        <p>Uma forma sutil de cobrar seus caloteiros(as)</p>
      </div>
    </div>
    """
  end

  # Private functions

  @spec get_api_key() :: {:ok, String.t()} | {:error, String.t()}
  defp get_api_key do
    case Application.get_env(:mepagueoque_api, :resend_api_key) do
      nil ->
        Logger.error("Resend API key is not configured")
        {:error, "Email service not configured"}

      "" ->
        Logger.error("Resend API key is empty")
        {:error, "Email service not configured"}

      key when is_binary(key) ->
        {:ok, key}
    end
  end

  @spec get_from_email() :: {:ok, String.t()} | {:error, String.t()}
  defp get_from_email do
    case Application.get_env(:mepagueoque_api, :from_email) do
      nil ->
        Logger.error("From email is not configured")
        {:error, "Email service not configured"}

      "" ->
        Logger.error("From email is empty")
        {:error, "Email service not configured"}

      email when is_binary(email) ->
        {:ok, email}
    end
  end

  @spec validate_email_format(String.t()) :: :ok | {:error, String.t()}
  defp validate_email_format(email) when is_binary(email) do
    # Basic email validation regex
    email_regex = ~r/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/

    if Regex.match?(email_regex, email) do
      :ok
    else
      Logger.warning("Invalid email format: #{email}")
      {:error, "Invalid email format"}
    end
  end

  @spec send_via_resend(String.t(), String.t(), String.t(), String.t()) :: email_result()
  defp send_via_resend(from, to, subject, html) do
    headers = [
      {"Authorization", "Bearer #{get_api_key!()}"},
      {"Content-Type", "application/json"}
    ]

    payload = %{
      from: from,
      to: [to],
      subject: subject,
      html: html
    }

    Logger.info("Sending email to: #{mask_email(to)}")

    case Req.post(@resend_api_url, headers: headers, json: payload) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        email_id = body["id"] || "unknown"
        Logger.info("Email sent successfully. ID: #{email_id}")
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Resend API returned status #{status}: #{inspect(body)}")
        error_message = extract_error_message(body)
        {:error, error_message}

      {:error, %{reason: reason}} ->
        Logger.error("Failed to send email via Resend: #{inspect(reason)}")
        {:error, "Email service error"}

      {:error, reason} ->
        Logger.error("Failed to send email via Resend: #{inspect(reason)}")
        {:error, "Email service error"}
    end
  end

  @spec get_api_key!() :: String.t()
  defp get_api_key! do
    case get_api_key() do
      {:ok, key} -> key
      {:error, _} -> raise "Resend API key not configured"
    end
  end

  @spec build_gif_html(GifData.t() | nil) :: String.t()
  defp build_gif_html(%GifData{} = gif_data) do
    if GifData.valid?(gif_data) do
      """
      <div style="margin: 20px 0;">
        <img
          src="#{gif_data.image_url}"
          width="#{gif_data.image_width}"
          height="#{gif_data.image_height}"
          alt="#{gif_data.title || "Payment reminder GIF"}"
          style="max-width: 100%; height: auto;"
        />
      </div>
      """
    else
      ""
    end
  end

  defp build_gif_html(_), do: ""

  @spec sanitize_html_content(String.t(), integer()) :: String.t()
  defp sanitize_html_content(content, max_length) when is_binary(content) do
    content
    |> String.slice(0, max_length)
    |> html_escape()
  end

  @spec html_escape(String.t()) :: String.t()
  defp html_escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  @spec mask_email(String.t()) :: String.t()
  defp mask_email(email) when is_binary(email) do
    case String.split(email, "@") do
      [local, domain] ->
        masked_local =
          if String.length(local) > 2 do
            first = String.first(local)
            last = String.last(local)
            "#{first}***#{last}"
          else
            "***"
          end

        "#{masked_local}@#{domain}"

      _ ->
        "***"
    end
  end

  @spec extract_error_message(map() | any()) :: String.t()
  defp extract_error_message(%{"message" => message}) when is_binary(message), do: message
  defp extract_error_message(%{"error" => error}) when is_binary(error), do: error
  defp extract_error_message(_), do: "Failed to send email"
end
