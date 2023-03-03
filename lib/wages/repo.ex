defmodule Wages.Repo do
  use Ecto.Repo,
    otp_app: :wages,
    adapter: Ecto.Adapters.Postgres
end
