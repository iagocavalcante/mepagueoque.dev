import Config

# Development-specific configuration
# Runtime configuration (API keys, etc.) is now in runtime.exs

# Enable debug logging in development
config :logger, level: :debug

# Enable code reloading
# Note: Hot code reloading is handled by the BEAM VM automatically

# Configure Ecto Repo for development (SQLite3)
config :mepagueoque_api, MepagueoqueApi.Repo,
  database: Path.expand("../data/mepagueoque_dev.db", __DIR__),
  pool_size: 5,
  show_sensitive_data_on_connection_error: true
