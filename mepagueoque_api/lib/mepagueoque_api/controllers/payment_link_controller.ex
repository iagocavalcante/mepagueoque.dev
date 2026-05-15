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

  require Logger

  alias MepagueoqueApi.Pix.BrCode
  alias MepagueoqueApi.Repo
  alias MepagueoqueApi.Schemas.PaymentLink
  alias MepagueoqueApi.Services.Turnstile

  @type create_error ::
          {:error, :invalid_params, map()}
          | {:error, :slug_taken}
          | {:error, :turnstile_verification_failed, String.t()}
          | {:error, :internal_error, String.t()}

  @type create_ok :: %{slug: String.t(), br_code: String.t(), expires_at: DateTime.t()}

  @spec create(Plug.Conn.t(), map()) :: {:ok, create_ok()} | create_error()
  def create(conn, params) do
    with {:ok, _} <- verify_turnstile(conn, params),
         {:ok, link} <- insert_link(params),
         {:ok, br_code} <- build_br_code(link) do
      {:ok, %{slug: link.slug, br_code: br_code, expires_at: link.expires_at}}
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
    changeset = PaymentLink.changeset(%PaymentLink{}, normalize_keys(params))

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

  # Convert string keys to existing atoms so the changeset cast picks them up.
  # If a key isn't a known atom, we leave the map untouched — `cast/4` will
  # drop unknown keys regardless.
  defp normalize_keys(params) when is_map(params) do
    Map.new(params, fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
      {k, v} -> {k, v}
    end)
  rescue
    ArgumentError -> params
  end

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

      true ->
        case conn.remote_ip do
          {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
          _ -> nil
        end
    end
  end
end
