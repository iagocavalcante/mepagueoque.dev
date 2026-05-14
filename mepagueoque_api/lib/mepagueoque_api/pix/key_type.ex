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
