ExUnit.start()

# Migrate the test DB before switching the sandbox to :manual mode.
# The migrator records applied migrations in `schema_migrations`, so this
# is idempotent across runs. The DB file path is configured in
# `config/test.exs` (a file path, not `:memory:`, so it survives across
# pool checkouts).
_ =
  Ecto.Migrator.run(
    MepagueoqueApi.Repo,
    Path.expand("../priv/repo/migrations", __DIR__),
    :up,
    all: true
  )

Ecto.Adapters.SQL.Sandbox.mode(MepagueoqueApi.Repo, :manual)
