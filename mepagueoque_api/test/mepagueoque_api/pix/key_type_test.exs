defmodule MepagueoqueApi.Pix.KeyTypeTest do
  use ExUnit.Case, async: true
  alias MepagueoqueApi.Pix.KeyType

  describe "detect/1" do
    test "detects CPF (11 digits)" do
      assert {:ok, :cpf} = KeyType.detect("12345678909")
      assert {:ok, :cpf} = KeyType.detect("123.456.789-09")
    end

    test "detects CNPJ (14 digits)" do
      assert {:ok, :cnpj} = KeyType.detect("12345678000190")
      assert {:ok, :cnpj} = KeyType.detect("12.345.678/0001-90")
    end

    test "detects email" do
      assert {:ok, :email} = KeyType.detect("iago@mepagueoque.dev")
    end

    test "detects phone (E.164 with +55)" do
      assert {:ok, :phone} = KeyType.detect("+5511999998888")
    end

    test "detects random key (UUID v4)" do
      assert {:ok, :random} = KeyType.detect("123e4567-e89b-12d3-a456-426614174000")
    end

    test "rejects garbage" do
      assert {:error, :invalid_pix_key} = KeyType.detect("not a key")
      assert {:error, :invalid_pix_key} = KeyType.detect("")
      assert {:error, :invalid_pix_key} = KeyType.detect(nil)
    end

    test "rejects keys with trailing newline (anchor sanity)" do
      assert {:error, :invalid_pix_key} = KeyType.detect("iago@example.com\n")
      assert {:error, :invalid_pix_key} = KeyType.detect("+5511999998888\n")
      assert {:error, :invalid_pix_key} = KeyType.detect("12345678909\n")
      assert {:error, :invalid_pix_key} = KeyType.detect("123e4567-e89b-12d3-a456-426614174000\n")
    end
  end

  describe "normalize/2" do
    test "strips formatting from CPF" do
      assert "12345678909" = KeyType.normalize("123.456.789-09", :cpf)
    end

    test "strips formatting from CNPJ" do
      assert "12345678000190" = KeyType.normalize("12.345.678/0001-90", :cnpj)
    end

    test "leaves email lowercase" do
      assert "iago@mepagueoque.dev" = KeyType.normalize("IAGO@MePagueoQue.dev", :email)
    end

    test "leaves phone unchanged" do
      assert "+5511999998888" = KeyType.normalize("+5511999998888", :phone)
    end

    test "leaves random unchanged (lowercase)" do
      assert "123e4567-e89b-12d3-a456-426614174000" =
               KeyType.normalize("123E4567-E89B-12D3-A456-426614174000", :random)
    end
  end
end
