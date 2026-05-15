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
      # length=5, "12.34"
      assert String.contains?(payload, "540512.34")
    end

    test "amount formatting: round numbers as '100.00'" do
      assert {:ok, payload} = BrCode.build(base_input(amount_cents: 10_000))
      # length=6
      assert String.contains?(payload, "5406100.00")
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

      assert {:error, :beneficiary_name_too_long} =
               BrCode.build(base_input(beneficiary_name: long))
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
