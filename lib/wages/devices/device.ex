defmodule Wages.Devices.Device do
  use Ecto.Schema
  import Ecto.Changeset

  schema "devices" do
    field :firmware_version, :string
    field :model, :string
    field :owner, :string
    field :serial_number, :string

    timestamps()
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:serial_number, :owner, :firmware_version, :model])
    |> validate_required([:serial_number, :owner, :firmware_version, :model])
  end
end
