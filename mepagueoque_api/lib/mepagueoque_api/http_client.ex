defmodule MepagueoqueApi.HTTPClient do
  @moduledoc """
  HTTP client wrapper with retry logic and proper error handling.

  This module provides a consistent interface for making HTTP requests across
  the application, with built-in retry logic, timeout handling, and error
  normalization.

  ## Configuration

  The client uses sensible defaults but can be configured per-request:
    - Timeout: 30 seconds default
    - Max retries: 3 attempts for transient failures
    - Retry delay: Exponential backoff starting at 100ms

  ## Features
    - Automatic retry for network errors and 5xx responses
    - Exponential backoff between retries
    - Proper timeout handling
    - Consistent error responses
  """

  require Logger

  @default_timeout 30_000
  @default_max_retries 3
  @default_retry_delay 100
  @retry_status_codes [500, 502, 503, 504]

  @type http_method :: :get | :post | :put | :patch | :delete
  @type options :: [
          timeout: non_neg_integer(),
          max_retries: non_neg_integer(),
          retry_delay: non_neg_integer(),
          headers: [{String.t(), String.t()}],
          params: keyword(),
          json: map(),
          form: map()
        ]

  @type response :: {:ok, %{status: integer(), body: any()}} | {:error, any()}

  @doc """
  Makes a GET request with retry logic.

  ## Parameters
    - url: The URL to request
    - opts: Keyword list of options (headers, params, timeout, etc.)

  ## Returns
    - `{:ok, %{status: integer(), body: map()}}` on success
    - `{:error, reason}` on failure after all retries

  ## Examples

      iex> HTTPClient.get("https://api.example.com/resource", params: [id: "123"])
      {:ok, %{status: 200, body: %{"data" => "..."}}}
  """
  @spec get(String.t(), options()) :: response()
  def get(url, opts \\ []) do
    make_request(:get, url, opts)
  end

  @doc """
  Makes a POST request with retry logic.

  ## Parameters
    - url: The URL to request
    - opts: Keyword list of options (headers, json, form, timeout, etc.)

  ## Returns
    - `{:ok, %{status: integer(), body: map()}}` on success
    - `{:error, reason}` on failure after all retries

  ## Examples

      iex> HTTPClient.post("https://api.example.com/resource", json: %{name: "test"})
      {:ok, %{status: 201, body: %{"id" => "123"}}}
  """
  @spec post(String.t(), options()) :: response()
  def post(url, opts \\ []) do
    make_request(:post, url, opts)
  end

  # Private functions

  @spec make_request(http_method(), String.t(), options()) :: response()
  defp make_request(method, url, opts) do
    max_retries = Keyword.get(opts, :max_retries, @default_max_retries)
    retry_delay = Keyword.get(opts, :retry_delay, @default_retry_delay)

    do_request_with_retry(method, url, opts, 0, max_retries, retry_delay)
  end

  @spec do_request_with_retry(
          http_method(),
          String.t(),
          options(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: response()
  defp do_request_with_retry(method, url, opts, attempt, max_retries, retry_delay) do
    case do_request(method, url, opts) do
      {:ok, response} = success ->
        if should_retry_status?(response.status) and attempt < max_retries do
          Logger.warning(
            "Request returned #{response.status}, retrying (#{attempt + 1}/#{max_retries})"
          )

          wait_time = calculate_backoff(retry_delay, attempt)
          Process.sleep(wait_time)
          do_request_with_retry(method, url, opts, attempt + 1, max_retries, retry_delay)
        else
          success
        end

      {:error, reason} = error ->
        if should_retry_error?(reason) and attempt < max_retries do
          Logger.warning(
            "Request failed with #{inspect(reason)}, retrying (#{attempt + 1}/#{max_retries})"
          )

          wait_time = calculate_backoff(retry_delay, attempt)
          Process.sleep(wait_time)
          do_request_with_retry(method, url, opts, attempt + 1, max_retries, retry_delay)
        else
          error
        end
    end
  end

  @spec do_request(http_method(), String.t(), options()) :: response()
  defp do_request(method, url, opts) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    req_opts =
      opts
      |> Keyword.take([:headers, :params, :json, :form])
      |> Keyword.put(:receive_timeout, timeout)

    case apply(Req, method, [url, req_opts]) do
      {:ok, %{status: status, body: body}} ->
        {:ok, %{status: status, body: body}}

      {:error, %{reason: reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec should_retry_status?(integer()) :: boolean()
  defp should_retry_status?(status), do: status in @retry_status_codes

  @spec should_retry_error?(any()) :: boolean()
  defp should_retry_error?(:timeout), do: true
  defp should_retry_error?(:econnrefused), do: true
  defp should_retry_error?(:closed), do: true
  defp should_retry_error?({:tls_alert, _}), do: true
  defp should_retry_error?(_), do: false

  @spec calculate_backoff(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp calculate_backoff(base_delay, attempt) do
    # Exponential backoff with jitter
    max_delay = base_delay * :math.pow(2, attempt)
    jitter = :rand.uniform(trunc(max_delay * 0.1))
    trunc(max_delay) + jitter
  end
end
