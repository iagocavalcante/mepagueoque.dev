defmodule MepagueoqueApi.Schemas.PaymentLink do
  @moduledoc """
  Ecto schema for shareable PIX payment links.

  The changeset is the validation entry point for user input. Every value
  produced here must be safe to feed into `MepagueoqueApi.Pix.BrCode.build/1`.

  Notable choices:
    * `inserted_at` and `expires_at` are explicit fields (not Ecto's
      auto-timestamps) so the changeset can derive `expires_at = inserted_at + 90 days`.
    * `slug` is auto-generated as a Crockford base32 ULID (10 chars timestamp
      + 16 chars random = 26 chars total, lowercased) when blank.
    * `pix_key_type` is derived from `pix_key` via `Pix.KeyType.detect/1` and
      the key itself is normalized (CPF/CNPJ stripped, email lowercased, etc.).
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias MepagueoqueApi.Pix.KeyType

  @ttl_days 90
  @slug_regex ~r/\A[a-z0-9-]+\z/
  @crockford "0123456789abcdefghjkmnpqrstvwxyz"

  @type t :: %__MODULE__{
          id: integer() | nil,
          slug: String.t() | nil,
          pix_key: String.t() | nil,
          pix_key_type: String.t() | nil,
          beneficiary_name: String.t() | nil,
          city: String.t() | nil,
          description: String.t() | nil,
          amount_cents: integer() | nil,
          inserted_at: DateTime.t() | nil,
          expires_at: DateTime.t() | nil
        }

  @primary_key {:id, :id, autogenerate: true}
  schema "payment_links" do
    field(:slug, :string)
    field(:pix_key, :string)
    field(:pix_key_type, :string)
    field(:beneficiary_name, :string)
    field(:city, :string)
    field(:description, :string)
    field(:amount_cents, :integer)
    field(:inserted_at, :utc_datetime)
    field(:expires_at, :utc_datetime)
  end

  @required_for_create [:pix_key, :beneficiary_name, :description, :amount_cents]
  @optional_for_create [:slug, :city]

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required_for_create ++ @optional_for_create)
    |> validate_required(@required_for_create)
    |> validate_length(:beneficiary_name, max: 25)
    |> validate_length(:city, max: 15)
    |> validate_length(:description, max: 72)
    |> validate_number(:amount_cents, greater_than: 0)
    |> put_default(:city, "BRASIL")
    |> generate_slug_if_blank()
    |> validate_format(:slug, @slug_regex,
      message: "deve conter apenas letras minúsculas, números e hífens"
    )
    |> validate_length(:slug, min: 3, max: 40)
    |> set_pix_key_type()
    |> set_timestamps()
    |> unique_constraint(:slug)
  end

  defp put_default(changeset, field, default) do
    case get_field(changeset, field) do
      nil -> put_change(changeset, field, default)
      "" -> put_change(changeset, field, default)
      _ -> changeset
    end
  end

  defp generate_slug_if_blank(changeset) do
    case get_field(changeset, :slug) do
      nil -> put_change(changeset, :slug, generate_ulid())
      "" -> put_change(changeset, :slug, generate_ulid())
      _ -> changeset
    end
  end

  defp generate_ulid do
    ts = System.system_time(:millisecond) |> encode_crockford(10)

    rand =
      :crypto.strong_rand_bytes(10)
      |> :binary.decode_unsigned()
      |> encode_crockford(16)

    String.downcase(ts <> rand)
  end

  defp encode_crockford(int, len) do
    int
    |> do_encode("")
    |> String.pad_leading(len, "0")
  end

  defp do_encode(0, ""), do: "0"
  defp do_encode(0, acc), do: acc

  defp do_encode(int, acc) do
    char = String.at(@crockford, rem(int, 32))
    do_encode(div(int, 32), char <> acc)
  end

  defp set_pix_key_type(changeset) do
    case get_field(changeset, :pix_key) do
      nil ->
        changeset

      key ->
        case KeyType.detect(key) do
          {:ok, type} ->
            normalized = KeyType.normalize(key, type)

            changeset
            |> put_change(:pix_key, normalized)
            |> put_change(:pix_key_type, Atom.to_string(type))

          {:error, _} ->
            add_error(changeset, :pix_key, "chave PIX inválida")
        end
    end
  end

  defp set_timestamps(changeset) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expires = DateTime.add(now, @ttl_days * 86_400, :second)

    changeset
    |> put_change(:inserted_at, now)
    |> put_change(:expires_at, expires)
  end
end
