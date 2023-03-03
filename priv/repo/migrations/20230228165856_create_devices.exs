defmodule Wages.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add :serial_number, :string
      add :owner, :string
      add :firmware_version, :string
      add :model, :string

      timestamps()
    end
  end
end
