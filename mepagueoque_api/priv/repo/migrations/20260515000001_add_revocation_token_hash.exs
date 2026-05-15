defmodule MepagueoqueApi.Repo.Migrations.AddRevocationTokenHash do
  use Ecto.Migration

  def change do
    alter table(:payment_links) do
      add(:revocation_token_hash, :string)
    end
  end
end
