defmodule MepagueoqueApi.Schemas.PaymentLinkTest do
  use ExUnit.Case, async: true
  alias MepagueoqueApi.Schemas.PaymentLink

  describe "changeset/2" do
    test "valid with all fields" do
      changeset = PaymentLink.changeset(%PaymentLink{}, valid_attrs())
      assert changeset.valid?
    end

    test "auto-generates slug when blank" do
      attrs = valid_attrs() |> Map.delete(:slug)
      changeset = PaymentLink.changeset(%PaymentLink{}, attrs)
      assert changeset.valid?
      slug = Ecto.Changeset.get_field(changeset, :slug)
      assert is_binary(slug)
      assert String.length(slug) == 26
    end

    test "rejects slug with invalid chars" do
      changeset = PaymentLink.changeset(%PaymentLink{}, %{valid_attrs() | slug: "has spaces"})
      refute changeset.valid?
      assert "deve conter apenas letras minúsculas, números e hífens" in errors_on(changeset).slug
    end

    test "rejects slug shorter than 3 chars" do
      changeset = PaymentLink.changeset(%PaymentLink{}, %{valid_attrs() | slug: "ab"})
      refute changeset.valid?
    end

    test "rejects slug longer than 40 chars" do
      changeset =
        PaymentLink.changeset(%PaymentLink{}, %{valid_attrs() | slug: String.duplicate("a", 41)})

      refute changeset.valid?
    end

    test "rejects invalid pix_key" do
      changeset = PaymentLink.changeset(%PaymentLink{}, %{valid_attrs() | pix_key: "garbage"})
      refute changeset.valid?
      assert "chave PIX inválida" in errors_on(changeset).pix_key
    end

    test "rejects amount_cents <= 0" do
      changeset = PaymentLink.changeset(%PaymentLink{}, %{valid_attrs() | amount_cents: 0})
      refute changeset.valid?
    end

    test "auto-sets expires_at to inserted_at + 90 days" do
      changeset = PaymentLink.changeset(%PaymentLink{}, valid_attrs())
      assert changeset.valid?
      inserted = Ecto.Changeset.get_field(changeset, :inserted_at)
      expires = Ecto.Changeset.get_field(changeset, :expires_at)
      assert DateTime.diff(expires, inserted, :day) == 90
    end

    test "sets pix_key_type from key" do
      changeset = PaymentLink.changeset(%PaymentLink{}, valid_attrs())
      assert Ecto.Changeset.get_field(changeset, :pix_key_type) == "email"
    end
  end

  defp valid_attrs do
    %{
      slug: "volei",
      pix_key: "iago@example.com",
      beneficiary_name: "IAGO",
      city: "BELEM",
      description: "VOLEI",
      amount_cents: 1500
    }
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
