defmodule Wages.DevicesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Wages.Devices` context.
  """

  alias Wages.Devices

  @doc """
  Generate a device.
  """
  def device_fixture(attrs \\ %{}) do
    {:ok, device} =
      attrs
      |> Enum.into(%{
        firmware_version: "some firmware_version",
        model: "some model",
        owner: "some owner",
        serial_number: "some serial_number",
        client_id: :crypto.strong_rand_bytes(16) |> Base.encode16()
      })
      |> Devices.create_device()

    device
  end
end
