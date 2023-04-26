defmodule Wages.Devices.Device do
  @moduledoc """
  The Device schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{
          id: integer(),
          firmware_version: String.t(),
          model: String.t(),
          owner: String.t(),
          serial_number: String.t(),
          client_id: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "devices" do
    field :firmware_version, :string
    field :model, :string
    field :owner, :string
    field :serial_number, :string
    field :client_id, :string

    timestamps()
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:serial_number, :owner, :firmware_version, :model, :client_id])
    |> validate_required([:client_id])
    |> unique_constraint(:client_id, name: :devices_client_id_index)
  end
end
