defmodule MepagueoqueApi.Application do
  @moduledoc """
  Main application supervisor for MePagueOQue API.

  This module implements the OTP Application behavior and defines the supervision
  tree for the application. It starts the HTTP server and manages the lifecycle
  of all child processes.

  ## Supervision Strategy

  Uses `:one_for_one` strategy, where if the web server crashes, it will be
  restarted independently without affecting other processes.

  ## Environment Configuration

  The application loads environment variables from a `.env` file if present,
  otherwise uses system environment variables. Configuration is managed through
  the standard Elixir configuration system.
  """

  use Application

  require Logger

  @impl true
  @doc """
  Starts the application supervision tree.

  This callback is invoked when the application starts. It:
  1. Loads environment variables from .env file (if present)
  2. Configures the HTTP server port
  3. Starts the Bandit web server with the router
  4. Sets up supervision for fault tolerance

  ## Parameters
    - type: Application start type (usually :normal)
    - args: Start arguments (typically empty list)

  ## Returns
    - `{:ok, pid}` on successful start
    - `{:error, reason}` if startup fails
  """
  def start(_type, _args) do
    # Load environment variables from .env file if it exists
    load_environment()

    port = get_port()

    children = [
      # Start the Bandit web server with the HTTP router
      # Bind to 0.0.0.0 to accept connections from Fly.io proxy
      {Bandit, plug: MepagueoqueApi.Router, port: port, scheme: :http, ip: {0, 0, 0, 0}}
    ]

    # Configure supervision strategy
    opts = [strategy: :one_for_one, name: MepagueoqueApi.Supervisor]

    Logger.info("Starting MePagueOQue API on port #{port}")

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("MePagueOQue API started successfully")
        {:ok, pid}

      {:error, reason} = error ->
        Logger.error("Failed to start MePagueOQue API: #{inspect(reason)}")
        error
    end
  end

  # Private functions

  @spec load_environment() :: :ok
  defp load_environment do
    try do
      Dotenvy.source!([".env", System.get_env()])
      Logger.debug("Environment variables loaded successfully")
      :ok
    rescue
      error ->
        Logger.warning("Failed to load .env file: #{inspect(error)}")
        Logger.info("Using system environment variables only")
        :ok
    end
  end

  @spec get_port() :: integer()
  defp get_port do
    Application.get_env(:mepagueoque_api, :port, 4000)
  end
end
