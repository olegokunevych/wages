defmodule Wages.DevicesTest do
  use Wages.DataCase

  alias Wages.Devices

  describe "devices" do
    alias Wages.Devices.Device

    import Wages.DevicesFixtures

    @invalid_attrs %{firmware_version: nil, model: nil, owner: nil, serial_number: nil}

    test "list_devices/0 returns all devices" do
      device = device_fixture()
      assert Devices.list_devices() == [device]
    end

    test "get_device!/1 returns the device with given id" do
      device = device_fixture()
      assert Devices.get_device!(device.id) == device
    end

    test "create_device/1 with valid data creates a device" do
      valid_attrs = %{
        firmware_version: "some firmware_version",
        model: "some model",
        owner: "some owner",
        serial_number: "some serial_number"
      }

      assert {:ok, %Device{} = device} = Devices.create_device(valid_attrs)
      assert device.firmware_version == "some firmware_version"
      assert device.model == "some model"
      assert device.owner == "some owner"
      assert device.serial_number == "some serial_number"
    end

    test "create_device/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Devices.create_device(@invalid_attrs)
    end

    test "update_device/2 with valid data updates the device" do
      device = device_fixture()

      update_attrs = %{
        firmware_version: "some updated firmware_version",
        model: "some updated model",
        owner: "some updated owner",
        serial_number: "some updated serial_number"
      }

      assert {:ok, %Device{} = device} = Devices.update_device(device, update_attrs)
      assert device.firmware_version == "some updated firmware_version"
      assert device.model == "some updated model"
      assert device.owner == "some updated owner"
      assert device.serial_number == "some updated serial_number"
    end

    test "update_device/2 with invalid data returns error changeset" do
      device = device_fixture()
      assert {:error, %Ecto.Changeset{}} = Devices.update_device(device, @invalid_attrs)
      assert device == Devices.get_device!(device.id)
    end

    test "delete_device/1 deletes the device" do
      device = device_fixture()
      assert {:ok, %Device{}} = Devices.delete_device(device)
      assert_raise Ecto.NoResultsError, fn -> Devices.get_device!(device.id) end
    end

    test "change_device/1 returns a device changeset" do
      device = device_fixture()
      assert %Ecto.Changeset{} = Devices.change_device(device)
    end
  end
end
