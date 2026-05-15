defmodule MepagueoqueApi.Workers.ExpirationSweeperTest do
  use MepagueoqueApi.DataCase, async: true
  alias MepagueoqueApi.Workers.ExpirationSweeper
  alias MepagueoqueApi.Schemas.PaymentLink

  test "deletes expired rows, keeps fresh ones" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    past = DateTime.add(now, -10, :second)
    future = DateTime.add(now, 86_400, :second)

    {:ok, _expired} = insert_link(%{slug: "expired-row", expires_at: past})
    {:ok, _alive} = insert_link(%{slug: "alive-row", expires_at: future})

    deleted = ExpirationSweeper.sweep()
    assert deleted == 1

    assert Repo.get_by(PaymentLink, slug: "alive-row")
    refute Repo.get_by(PaymentLink, slug: "expired-row")
  end

  defp insert_link(overrides) do
    attrs = %{
      slug: "x",
      pix_key: "iago@example.com",
      pix_key_type: "email",
      beneficiary_name: "IAGO",
      city: "BELEM",
      description: "VOLEI",
      amount_cents: 1500,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      expires_at:
        DateTime.utc_now() |> DateTime.add(86_400, :second) |> DateTime.truncate(:second)
    }

    %PaymentLink{}
    |> Ecto.Changeset.change(Map.merge(attrs, overrides))
    |> Repo.insert()
  end
end
