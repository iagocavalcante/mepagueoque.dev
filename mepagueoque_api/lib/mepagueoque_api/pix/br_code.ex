defmodule MepagueoqueApi.Pix.BrCode do
  @moduledoc """
  EMV-BR `copia e cola` payload generator for PIX static QR codes.

  Implements the BCB "Manual de Padrões para Iniciação do Pix" TLV format
  with CRC16-CCITT/FALSE (poly 0x1021, init 0xFFFF, no reflection).

  ## Boundary assumptions

    * PIX keys are assumed ASCII; upstream validation in `MepagueoqueApi.Pix.KeyType`
      enforces this for the formats this product supports (cpf, cnpj, email, phone, random).
    * Amount is required (`amount_cents > 0`). This module does not emit amountless
      QRs (BCB allows them, but the product spec requires a fixed amount).
    * TXID sanitization is permissive of space, `.`, `/`, and `-` for readability —
      real-world bank apps accept this; strict BCB validators may not. Tightening
      to `[A-Za-z0-9]` only is a one-line change if certification is later required.
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
        merchant_account(input.pix_key),
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
    body_size = byte_size(payload) - 4
    <<body::binary-size(body_size), given_crc::binary-size(4)>> = payload
    String.upcase(given_crc) == crc16(body)
  end

  def valid_crc?(_), do: false

  # ── TLV helpers ────────────────────────────────────────────────────────────

  defp tlv(id, value) do
    len = value |> byte_size() |> Integer.to_string() |> String.pad_leading(2, "0")
    id <> len <> value
  end

  defp merchant_account(pix_key) do
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
    cents_part = rem(cents, 100)
    "#{reais}." <> String.pad_leading(Integer.to_string(cents_part), 2, "0")
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
    "á" => "a",
    "à" => "a",
    "â" => "a",
    "ã" => "a",
    "ä" => "a",
    "é" => "e",
    "è" => "e",
    "ê" => "e",
    "ë" => "e",
    "í" => "i",
    "ì" => "i",
    "î" => "i",
    "ï" => "i",
    "ó" => "o",
    "ò" => "o",
    "ô" => "o",
    "õ" => "o",
    "ö" => "o",
    "ú" => "u",
    "ù" => "u",
    "û" => "u",
    "ü" => "u",
    "ç" => "c",
    "ñ" => "n",
    "Á" => "A",
    "À" => "A",
    "Â" => "A",
    "Ã" => "A",
    "Ä" => "A",
    "É" => "E",
    "È" => "E",
    "Ê" => "E",
    "Ë" => "E",
    "Í" => "I",
    "Ì" => "I",
    "Î" => "I",
    "Ï" => "I",
    "Ó" => "O",
    "Ò" => "O",
    "Ô" => "O",
    "Õ" => "O",
    "Ö" => "O",
    "Ú" => "U",
    "Ù" => "U",
    "Û" => "U",
    "Ü" => "U",
    "Ç" => "C",
    "Ñ" => "N"
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
