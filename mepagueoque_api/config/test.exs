import Config

# Test configuration
config :mepagueoque_api,
  port: 4001,
  turnstile_bypass_token: "bypass"

config :logger, level: :warning

# Configure Ecto Repo for test.
#
# SQLite's `:memory:` databases are private to each connection, which breaks
# pooling — the migrator's checkout would create one DB, then test checkouts
# get fresh empty DBs. We use a temp file path instead so every pooled
# connection sees the same schema. The Sandbox still keeps each test isolated
# by wrapping it in a transaction.
#
# `journal_mode: :wal` + `busy_timeout` avoid the noisy "database is locked"
# warnings when multiple pool connections race to open the file at boot.
config :mepagueoque_api, MepagueoqueApi.Repo,
  database: Path.expand("../tmp/test.db", __DIR__),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5,
  journal_mode: :wal,
  busy_timeout: 5_000
