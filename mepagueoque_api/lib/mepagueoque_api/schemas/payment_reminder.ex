defmodule MepagueoqueApi.Schemas.PaymentReminder do
  @moduledoc """
  Schema for payment reminder requests.

  This module defines the structure and validation for payment reminder requests
  received from the API clients.
  """

  @type t :: %__MODULE__{
          text: String.t(),
          value: String.t(),
          destination: String.t(),
          token: String.t()
        }

  @enforce_keys [:text, :value, :destination, :token]
  defstruct [:text, :value, :destination, :token]

  @doc """
  Creates a new PaymentReminder struct from request parameters.

  ## Parameters
    - params: Map containing the payment reminder data

  ## Returns
    - {:ok, %PaymentReminder{}} if params are valid
    - {:error, :invalid_params, reasons} if validation fails

  ## Examples

      iex> PaymentReminder.new(%{"text" => "Pay me!", "value" => "100", "destination" => "test@example.com", "token" => "abc"})
      {:ok, %PaymentReminder{text: "Pay me!", value: "100", destination: "test@example.com", token: "abc"}}

      iex> PaymentReminder.new(%{})
      {:error, :invalid_params, ["text is required", "value is required", "destination is required", "token is required"]}
  """
  @spec new(map()) :: {:ok, t()} | {:error, :invalid_params, [String.t()]}
  def new(params) when is_map(params) do
    with {:ok, validated} <- validate_required_fields(params),
         {:ok, sanitized} <- sanitize_params(validated) do
      {:ok,
       %__MODULE__{
         text: sanitized.text,
         value: sanitized.value,
         destination: sanitized.destination,
         token: sanitized.token
       }}
    end
  end

  @spec validate_required_fields(map()) ::
          {:ok, map()} | {:error, :invalid_params, [String.t()]}
  defp validate_required_fields(params) do
    required_fields = [:text, :value, :destination, :token]

    errors =
      required_fields
      |> Enum.reduce([], fn field, acc ->
        field_str = to_string(field)
        value = params[field_str] || params[field]

        cond do
          is_nil(value) ->
            ["#{field_str} is required" | acc]

          not is_binary(value) ->
            ["#{field_str} must be a string" | acc]

          String.trim(value) == "" ->
            ["#{field_str} cannot be empty" | acc]

          true ->
            acc
        end
      end)
      |> Enum.reverse()

    case errors do
      [] -> {:ok, params}
      errors -> {:error, :invalid_params, errors}
    end
  end

  @spec sanitize_params(map()) :: {:ok, map()}
  defp sanitize_params(params) do
    sanitized = %{
      text: sanitize_string(params["text"] || params[:text]),
      value: sanitize_string(params["value"] || params[:value]),
      destination: sanitize_email(params["destination"] || params[:destination]),
      token: sanitize_token(params["token"] || params[:token])
    }

    {:ok, sanitized}
  end

  @spec sanitize_string(String.t()) :: String.t()
  defp sanitize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.slice(0, 1000)
  end

  @spec sanitize_token(String.t()) :: String.t()
  defp sanitize_token(value) when is_binary(value) do
    # Turnstile tokens can be up to ~1100 characters
    # Don't truncate them - just trim whitespace
    String.trim(value)
  end

  @spec sanitize_email(String.t()) :: String.t()
  defp sanitize_email(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.slice(0, 254)
  end
end
