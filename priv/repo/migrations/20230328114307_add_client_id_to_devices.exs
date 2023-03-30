defmodule Wages.Repo.Migrations.AddClientIdToDevices do
  use Ecto.Migration

  def change do
    alter table(:devices) do
      add :client_id, :string
    end

    create(unique_index(:devices, [:client_id], name: :devices_client_id_index))
  end
end
