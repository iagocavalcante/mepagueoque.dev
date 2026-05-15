defmodule MepagueoqueApi.Repo.Migrations.CreatePaymentLinks do
  use Ecto.Migration

  def change do
    create table(:payment_links) do
      add(:slug, :string, null: false)
      add(:pix_key, :string, null: false)
      add(:pix_key_type, :string, null: false)
      add(:beneficiary_name, :string, null: false)
      add(:city, :string, null: false)
      add(:description, :string, null: false)
      add(:amount_cents, :integer, null: false)
      add(:inserted_at, :utc_datetime, null: false)
      add(:expires_at, :utc_datetime, null: false)
    end

    create(unique_index(:payment_links, [:slug]))
    create(index(:payment_links, [:expires_at]))
  end
end
