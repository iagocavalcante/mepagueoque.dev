defmodule MepagueoqueApi.Controllers.PaymentLinkController do
  @moduledoc """
  Create + fetch payment links.

  Flow for `create/2`:
    1. Verify Cloudflare Turnstile (or bypass in test via `:turnstile_bypass_token`)
    2. Insert the row via `PaymentLink.changeset/2`
    3. Build the EMV-BR `copia e cola` payload from the persisted row

  Slug uniqueness is enforced by the DB `unique_index` and surfaced as
  `{:error, :slug_taken}` via the `unique_constraint(:slug)` in the changeset.
  """

  import Ecto.Query

  alias MepagueoqueApi.Pix.BrCode
  alias MepagueoqueApi.Repo
  alias MepagueoqueApi.Schemas.PaymentLink
  alias MepagueoqueApi.Services.Turnstile

  @type create_error ::
          {:error, :invalid_params, map()}
          | {:error, :slug_taken}
          | {:error, :turnstile_verification_failed, String.t()}
          | {:error, :internal_error, String.t()}

  @type create_ok :: %{
          slug: String.t(),
          br_code: String.t(),
          expires_at: DateTime.t(),
          revocation_token: String.t()
        }

  @spec create(Plug.Conn.t(), map()) :: {:ok, create_ok()} | create_error()
  def create(conn, params) do
    revocation_token = generate_revocation_token()

    params_with_hash =
      Map.put(params, "revocation_token_hash", hash_revocation_token(revocation_token))

    with {:ok, _} <- verify_turnstile(conn, params),
         {:ok, link} <- insert_link(params_with_hash),
         {:ok, br_code} <- build_br_code(link) do
      {:ok,
       %{
         slug: link.slug,
         br_code: br_code,
         expires_at: link.expires_at,
         revocation_token: revocation_token
       }}
    end
  end

  @doc """
  Revoke (delete) a payment link. Requires the raw revocation token returned
  on creation. Compares its SHA-256 hash against the stored hash in constant
  time to avoid timing attacks.
  """
  @spec revoke(String.t(), String.t()) ::
          :ok | {:error, :not_found} | {:error, :unauthorized}
  def revoke(slug, token) when is_binary(slug) and is_binary(token) do
    case Repo.get_by(PaymentLink, slug: slug) do
      nil ->
        {:error, :not_found}

      %PaymentLink{revocation_token_hash: nil} ->
        # Pre-revocation-feature link — can't be revoked via this endpoint.
        {:error, :unauthorized}

      %PaymentLink{revocation_token_hash: stored_hash} = link ->
        given_hash = hash_revocation_token(token)

        if Plug.Crypto.secure_compare(given_hash, stored_hash) do
          Repo.delete(link)
          :ok
        else
          {:error, :unauthorized}
        end
    end
  end

  def revoke(_, _), do: {:error, :not_found}

  # ── Revocation token ──────────────────────────────────────────────────────

  defp generate_revocation_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  defp hash_revocation_token(token) do
    :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)
  end

  @spec show(String.t()) ::
          {:ok,
           %{
             slug: String.t(),
             beneficiary_name: String.t(),
             description: String.t(),
             amount_cents: integer(),
             br_code: String.t(),
             expires_at: DateTime.t()
           }}
          | {:error, :not_found}
  def show(slug) when is_binary(slug) do
    now = DateTime.utc_now()

    query =
      from(p in PaymentLink,
        where: p.slug == ^slug and p.expires_at > ^now
      )

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      link ->
        case build_br_code(link) do
          {:ok, br_code} ->
            {:ok,
             %{
               slug: link.slug,
               beneficiary_name: link.beneficiary_name,
               description: link.description,
               amount_cents: link.amount_cents,
               br_code: br_code,
               expires_at: link.expires_at
             }}

          {:error, :internal_error, _} ->
            {:error, :not_found}
        end
    end
  end

  # ── Turnstile ──────────────────────────────────────────────────────────────

  defp verify_turnstile(conn, %{"token" => token}) when is_binary(token) do
    bypass = Application.get_env(:mepagueoque_api, :turnstile_bypass_token)

    cond do
      bypass && token == bypass ->
        {:ok, :bypassed}

      true ->
        ip = client_ip(conn)

        case Turnstile.verify(token, ip) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, :turnstile_verification_failed, reason}
        end
    end
  end

  defp verify_turnstile(_conn, _params),
    do: {:error, :turnstile_verification_failed, "missing token"}

  # ── Insert ────────────────────────────────────────────────────────────────

  defp insert_link(params) do
    changeset = PaymentLink.changeset(%PaymentLink{}, params)

    case Repo.insert(changeset) do
      {:ok, link} ->
        {:ok, link}

      {:error, %Ecto.Changeset{errors: errors} = cs} ->
        if slug_collision?(errors) do
          {:error, :slug_taken}
        else
          {:error, :invalid_params, format_errors(cs)}
        end
    end
  end

  defp slug_collision?(errors) do
    case Keyword.get(errors, :slug) do
      {_msg, opts} -> Keyword.get(opts, :constraint) == :unique
      _ -> false
    end
  end

  # ── BR Code ───────────────────────────────────────────────────────────────

  defp build_br_code(%PaymentLink{} = link) do
    case BrCode.build(%{
           pix_key: link.pix_key,
           beneficiary_name: link.beneficiary_name,
           city: link.city,
           description: link.description,
           amount_cents: link.amount_cents
         }) do
      {:ok, code} -> {:ok, code}
      {:error, reason} -> {:error, :internal_error, "BR Code build failed: #{reason}"}
    end
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp format_errors(%Ecto.Changeset{} = cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc ->
        String.replace(acc, "%{#{k}}", to_string(v))
      end)
    end)
  end

  defp client_ip(%Plug.Conn{} = conn) do
    cond do
      ip = conn |> Plug.Conn.get_req_header("fly-client-ip") |> List.first() ->
        ip

      ip = conn |> Plug.Conn.get_req_header("cf-connecting-ip") |> List.first() ->
        ip

      forwarded = conn |> Plug.Conn.get_req_header("x-forwarded-for") |> List.first() ->
        forwarded |> String.split(",") |> List.first() |> String.trim()

      real_ip = conn |> Plug.Conn.get_req_header("x-real-ip") |> List.first() ->
        real_ip

      true ->
        case conn.remote_ip do
          {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
          _ -> nil
        end
    end
  end
end
