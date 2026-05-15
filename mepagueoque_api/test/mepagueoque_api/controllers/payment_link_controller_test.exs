defmodule MepagueoqueApi.Controllers.PaymentLinkControllerTest do
  use MepagueoqueApi.DataCase, async: true

  alias MepagueoqueApi.Controllers.PaymentLinkController
  alias MepagueoqueApi.Schemas.PaymentLink

  describe "create/2 (Turnstile bypassed in test)" do
    test "creates row with auto-slug" do
      params = %{
        "pix_key" => "iago@example.com",
        "beneficiary_name" => "IAGO",
        "city" => "BELEM",
        "description" => "VOLEI",
        "amount_cents" => 1500,
        "token" => "bypass"
      }

      assert {:ok, %{slug: slug, br_code: br_code, expires_at: expires_at}} =
               PaymentLinkController.create(build_conn(), params)

      assert is_binary(slug) and String.length(slug) >= 3
      assert String.contains?(br_code, "iago@example.com")
      assert %DateTime{} = expires_at
      assert Repo.get_by(PaymentLink, slug: slug)
    end

    test "honors user-provided slug" do
      params = base_params(%{"slug" => "voleizinho"})

      assert {:ok, %{slug: "voleizinho"}} =
               PaymentLinkController.create(build_conn(), params)
    end

    test "rejects slug collision with :slug_taken" do
      assert {:ok, _} =
               PaymentLinkController.create(build_conn(), base_params(%{"slug" => "dup"}))

      assert {:error, :slug_taken} =
               PaymentLinkController.create(build_conn(), base_params(%{"slug" => "dup"}))
    end

    test "rejects invalid params with :invalid_params" do
      assert {:error, :invalid_params, _errors} =
               PaymentLinkController.create(build_conn(), %{"token" => "bypass"})
    end
  end

  describe "show/1" do
    test "returns link payload + BR code" do
      {:ok, %{slug: slug}} =
        PaymentLinkController.create(build_conn(), base_params(%{"slug" => "live"}))

      assert {:ok, payload} = PaymentLinkController.show(slug)

      assert payload.slug == "live"
      assert payload.beneficiary_name == "IAGO"
      assert payload.description == "VOLEI"
      assert payload.amount_cents == 1500
      assert String.contains?(payload.br_code, "iago@example.com")
      assert %DateTime{} = payload.expires_at
    end

    test "returns :not_found when slug missing" do
      assert {:error, :not_found} = PaymentLinkController.show("nope")
    end

    test "returns :not_found for expired link" do
      {:ok, %{slug: slug}} =
        PaymentLinkController.create(build_conn(), base_params(%{"slug" => "old"}))

      past = DateTime.add(DateTime.utc_now(), -1, :second)
      Repo.update_all(from(p in PaymentLink, where: p.slug == ^slug), set: [expires_at: past])
      assert {:error, :not_found} = PaymentLinkController.show("old")
    end
  end

  defp build_conn do
    %Plug.Conn{remote_ip: {127, 0, 0, 1}, req_headers: []}
  end

  defp base_params(overrides) do
    Map.merge(
      %{
        "pix_key" => "iago@example.com",
        "beneficiary_name" => "IAGO",
        "city" => "BELEM",
        "description" => "VOLEI",
        "amount_cents" => 1500,
        "token" => "bypass"
      },
      overrides
    )
  end
end
