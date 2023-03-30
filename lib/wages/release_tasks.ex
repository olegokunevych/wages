defmodule Wages.ReleaseTasks do
  @moduledoc false
  alias Ecto.Migrator

  @doc false
  def migrate do
    {:ok, _} = Application.ensure_all_started(:wages)
    _ = Migrator.run(Wages.Repo, :up, all: true)
    :init.stop()
  end
end
