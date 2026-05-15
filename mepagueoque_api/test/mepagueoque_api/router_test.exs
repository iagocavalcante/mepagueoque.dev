defmodule MepagueoqueApi.RouterTest do
  use MepagueoqueApi.DataCase, async: true
  use Plug.Test

  alias MepagueoqueApi.Router

  @opts Router.init([])

  describe "POST /pagamentos" do
    test "returns 200 + url + br_code on success" do
      body =
        Jason.encode!(%{
          pix_key: "iago@example.com",
          beneficiary_name: "IAGO",
          city: "BELEM",
          description: "VOLEI",
          amount_cents: 1500,
          token: "bypass"
        })

      conn =
        :post
        |> conn("/pagamentos", body)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["slug"]
      assert response["br_code"]
      assert response["url"] == "https://mepagueoque.dev/p/#{response["slug"]}"
    end

    test "returns 409 on slug collision" do
      body =
        Jason.encode!(%{
          pix_key: "iago@example.com",
          beneficiary_name: "IAGO",
          city: "BELEM",
          description: "VOLEI",
          amount_cents: 1500,
          slug: "taken",
          token: "bypass"
        })

      # First call succeeds
      conn1 =
        :post
        |> conn("/pagamentos", body)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn1.status == 200

      # Second call collides
      conn2 =
        :post
        |> conn("/pagamentos", body)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn2.status == 409
      assert Jason.decode!(conn2.resp_body)["error"] == "slug_taken"
    end

    test "returns 400 on missing fields" do
      body = Jason.encode!(%{token: "bypass"})

      conn =
        :post
        |> conn("/pagamentos", body)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 400
    end
  end

  describe "GET /pagamentos/:slug" do
    test "returns 200 with payload for existing link" do
      # Create one first via POST
      body =
        Jason.encode!(%{
          pix_key: "iago@example.com",
          beneficiary_name: "IAGO",
          city: "BELEM",
          description: "VOLEI",
          amount_cents: 1500,
          slug: "showme",
          token: "bypass"
        })

      :post
      |> conn("/pagamentos", body)
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

      conn =
        :get
        |> conn("/pagamentos/showme")
        |> Router.call(@opts)

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["slug"] == "showme"
      assert response["br_code"]
    end

    test "returns 404 for missing slug" do
      conn =
        :get
        |> conn("/pagamentos/nope")
        |> Router.call(@opts)

      assert conn.status == 404
      assert Jason.decode!(conn.resp_body)["error"] == "not_found"
    end
  end
end
