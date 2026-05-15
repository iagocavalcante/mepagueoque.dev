defmodule MepagueoqueApi.Repo do
  use Ecto.Repo,
    otp_app: :mepagueoque_api,
    adapter: Ecto.Adapters.SQLite3
end
