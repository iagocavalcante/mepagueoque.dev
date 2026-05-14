import Config

# Test configuration
config :mepagueoque_api,
  port: 4001

config :logger, level: :warning

# Configure Ecto Repo for test (in-memory SQLite3 with Sandbox pool)
config :mepagueoque_api, MepagueoqueApi.Repo,
  database: ":memory:",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5
