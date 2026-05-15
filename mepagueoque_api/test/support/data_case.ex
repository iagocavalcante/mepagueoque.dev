defmodule MepagueoqueApi.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring access to the Repo.

  It wraps each test in an `Ecto.Adapters.SQL.Sandbox` checkout so that
  database state from one test does not leak into another. Tests are
  isolated even when running `async: true`.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias MepagueoqueApi.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import MepagueoqueApi.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MepagueoqueApi.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
