defmodule MepagueoqueApi.Services.Giphy do
  @moduledoc """
  Service for fetching random GIFs from Giphy API.

  This service integrates with Giphy's API to retrieve random money-themed GIFs
  for inclusion in payment reminder emails. It handles API authentication,
  request formatting, and response parsing.

  ## Configuration

  Required environment variables:
    - GIPHY_API_KEY: Your Giphy API key
    - GIPHY_URL: Base URL for Giphy API (defaults to https://api.giphy.com/v1/gifs)

  ## References
    - [Giphy API Documentation](https://developers.giphy.com/docs/api/)
  """

  require Logger

  alias MepagueoqueApi.Schemas.GifData

  @default_giphy_url "https://api.giphy.com/v1/gifs"
  @default_tag "money"
  @default_rating "g"

  # Fallback tags to try if primary tag returns no results
  @fallback_tags ["cash", "dollar", "rich", "payment", "payday"]

  @type gif_options :: [
          tag: String.t(),
          rating: String.t()
        ]

  @doc """
  Fetches a random money-themed GIF from Giphy.

  This function queries Giphy's random endpoint with a "money" tag to retrieve
  an appropriate GIF for payment reminder emails. All returned GIFs are rated "G"
  to ensure appropriate content.

  ## Fallback Strategy

  If the primary tag ("money") returns no results, the function automatically
  tries the following fallback tags in sequence:
    1. "cash" - physical money
    2. "dollar" - US currency
    3. "rich" - wealth theme
    4. "payment" - payment related
    5. "payday" - payday theme

  This ensures a GIF is found even if some tags have limited results.

  ## Returns
    - `{:ok, gif_data}` containing URL and metadata if successful
    - `{:error, reason}` if the request fails

  ## Examples

      iex> Giphy.fetch_random_money_gif()
      {:ok, %{url: "https://giphy.com/gifs/...", image_url: "https://media.giphy.com/...", ...}}

      iex> Giphy.fetch_random_money_gif()
      {:error, "Giphy service unavailable"}

  ## Error Cases
    - Configuration missing: API key not set
    - Network error: Unable to reach Giphy API
    - Invalid response: Unexpected response format
    - Service unavailable: Giphy API returned error status
    - No GIFs available: No GIFs found with any tag (rare)
  """
  @spec fetch_random_money_gif(gif_options()) ::
          {:ok, GifData.t()} | {:error, String.t()}
  def fetch_random_money_gif(opts \\ []) do
    tag = Keyword.get(opts, :tag, @default_tag)
    rating = Keyword.get(opts, :rating, @default_rating)

    with {:ok, api_key} <- get_api_key(),
         {:ok, base_url} <- get_base_url() do
      # Try with primary tag first, then fallback tags
      try_with_fallback_tags(base_url, api_key, tag, rating, @fallback_tags)
    end
  end

  @spec try_with_fallback_tags(String.t(), String.t(), String.t(), String.t(), [String.t()]) ::
          {:ok, GifData.t()} | {:error, String.t()}
  defp try_with_fallback_tags(base_url, api_key, primary_tag, rating, fallback_tags) do
    # Try primary tag first
    case try_fetch_with_params(base_url, api_key, primary_tag, rating) do
      {:ok, gif_data} ->
        {:ok, gif_data}

      {:error, "No GIFs available"} ->
        # Try each fallback tag in sequence
        Logger.warning("No GIFs found with tag '#{primary_tag}', trying fallback tags")
        try_fallback_tags(base_url, api_key, rating, fallback_tags)

      error ->
        error
    end
  end

  @spec try_fallback_tags(String.t(), String.t(), String.t(), [String.t()]) ::
          {:ok, GifData.t()} | {:error, String.t()}
  defp try_fallback_tags(_base_url, _api_key, _rating, []) do
    Logger.error("No GIFs found with any fallback tags")
    {:error, "No GIFs available"}
  end

  defp try_fallback_tags(base_url, api_key, rating, [tag | rest]) do
    Logger.debug("Trying fallback tag: '#{tag}'")

    case try_fetch_with_params(base_url, api_key, tag, rating) do
      {:ok, gif_data} ->
        Logger.info("Successfully found GIF with fallback tag: '#{tag}'")
        {:ok, gif_data}

      {:error, "No GIFs available"} ->
        # Try next tag
        try_fallback_tags(base_url, api_key, rating, rest)

      error ->
        # Other errors (API issues, etc.) should fail immediately
        error
    end
  end

  @spec try_fetch_with_params(String.t(), String.t(), String.t() | nil, String.t()) ::
          {:ok, GifData.t()} | {:error, String.t()}
  defp try_fetch_with_params(base_url, api_key, tag, rating) do
    with {:ok, response} <- make_giphy_request(base_url, api_key, tag, rating),
         {:ok, gif_data} <- parse_response(response) do
      {:ok, gif_data}
    end
  end

  @spec get_api_key() :: {:ok, String.t()} | {:error, String.t()}
  defp get_api_key do
    case Application.get_env(:mepagueoque_api, :giphy_api_key) do
      nil ->
        Logger.error("Giphy API key is not configured")
        {:error, "Giphy configuration missing"}

      "" ->
        Logger.error("Giphy API key is empty")
        {:error, "Giphy configuration missing"}

      key when is_binary(key) ->
        Logger.debug("Giphy API key loaded: #{String.slice(key, 0..5)}...")
        {:ok, key}
    end
  end

  @spec get_base_url() :: {:ok, String.t()}
  defp get_base_url do
    url =
      Application.get_env(:mepagueoque_api, :giphy_url, @default_giphy_url)
      |> String.trim_trailing("/")

    {:ok, url}
  end

  @spec make_giphy_request(String.t(), String.t(), String.t() | nil, String.t()) ::
          {:ok, map()} | {:error, String.t()}
  defp make_giphy_request(base_url, api_key, tag, rating) do
    url = "#{base_url}/random"

    # Build params - only add tag if present
    params =
      [api_key: api_key, rating: rating]
      |> maybe_add_tag(tag)

    tag_info = if tag, do: "tag: '#{tag}'", else: "no tag filter"
    Logger.debug("Fetching random GIF from Giphy with #{tag_info}, rating: '#{rating}'")

    case Req.get(url, params: params) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        Logger.debug("Successfully fetched GIF from Giphy")
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Giphy API returned status #{status}: #{inspect(body)}")
        {:error, "Giphy service unavailable"}

      {:error, %{reason: reason}} ->
        Logger.error("Failed to fetch GIF from Giphy: #{inspect(reason)}")
        {:error, "Failed to fetch GIF"}

      {:error, reason} ->
        Logger.error("Failed to fetch GIF from Giphy: #{inspect(reason)}")
        {:error, "Failed to fetch GIF"}
    end
  end

  @spec parse_response(map()) :: {:ok, GifData.t()} | {:error, String.t()}
  defp parse_response(body) when is_map(body) do
    Logger.debug("Giphy response body: #{inspect(body, pretty: true)}")

    # Check if data is an empty array (no results)
    case body do
      %{"data" => []} ->
        Logger.error("No GIFs found matching the search criteria")
        {:error, "No GIFs available"}

      %{"data" => data} when is_map(data) ->
        # Data is a map (expected for random endpoint)
        gif_data = GifData.from_giphy_response(body)

        if GifData.valid?(gif_data) do
          {:ok, gif_data}
        else
          Logger.error("Invalid GIF data received from Giphy: #{inspect(body)}")
          {:error, "Invalid GIF data"}
        end

      _ ->
        Logger.error("Unexpected response format from Giphy: #{inspect(body)}")
        {:error, "Invalid response format"}
    end
  end

  defp parse_response(_body) do
    Logger.error("Unexpected response format from Giphy")
    {:error, "Invalid response format"}
  end

  @spec maybe_add_tag(keyword(), String.t() | nil) :: keyword()
  defp maybe_add_tag(params, nil), do: params
  defp maybe_add_tag(params, tag) when is_binary(tag) and tag != "" do
    [{:tag, tag} | params]
  end
  defp maybe_add_tag(params, _), do: params
end
