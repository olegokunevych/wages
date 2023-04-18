defmodule Wages.Repo do
  use Ecto.Repo,
    otp_app: :wages,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 20
end
