defmodule Wages.DevicesTest do
  use Wages.DataCase
  import Mock

  alias Scrivener.Page
  alias Wages.Devices
  alias Wages.Devices.Device
  alias Wages.Influxdb.Connection, as: InfluxdbConn

  import Wages.DevicesFixtures

  @invalid_attrs %{client_id: nil}
  @influx_db_name "wages_test"
  @influxdb_resp [
    %{
      "_field" => "temperature",
      "_measurement" => "temperature",
      "_start" => "2021-01-01T00:00:00Z",
      "_stop" => "2021-01-01T00:00:00Z",
      "_time" => "2021-01-01T00:00:00Z",
      "_value" => 1.0,
      "client_id" => "AAAA1111BBBB2222",
      "session_id" => "CCCC3333DDDD4444"
    }
  ]

  test "list_devices/0 returns all devices" do
    device = device_fixture()
    assert %Page{entries: [^device]} = Devices.list_devices()
  end

  test "list_devices_with_mqtt_info/1 returns all devices with mqtt info" do
    device = device_fixture()
    assert %Page{entries: [^device]} = Devices.list_devices_with_mqtt_info()
  end

  test "get_device/1 returns the device with given id" do
    device = device_fixture()
    assert Devices.get_device(device.id) == {:ok, device}
  end

  describe "get_device_by_client_id" do
    test "get_device_by_client_id/1 returns the device with given client_id" do
      device = device_fixture()
      assert Devices.get_device_by_client_id(device.client_id) == {:ok, device}
    end

    test "get_device_by_client_id/1 returns nil if no device with given client_id" do
      assert Devices.get_device_by_client_id("some client_id") == {:error, :not_found}
    end
  end

  describe "get_device_with_mqtt_info" do
    test_with_mock "get_device_with_mqtt_info/1 returns the device with given id", InfluxdbConn,
      config: fn :database -> @influx_db_name end,
      query: fn _, _ -> @influxdb_resp end do
      device = device_fixture()

      assert Devices.get_device_with_mqtt_info(device.id) ==
               {:ok, device,
                %{
                  "CCCC3333DDDD4444" => [
                    %{
                      "_time" => "2021-01-01T00:00:00Z",
                      "_value" => 1.0,
                      "session_id" => "CCCC3333DDDD4444"
                    }
                  ]
                }}
    end

    test_with_mock "get_device_with_mqtt_info/1 returns device result without timeseries data if no influxdb connection",
                   InfluxdbConn,
                   config: fn :database -> @influx_db_name end,
                   query: fn _, _ -> {:error, :nxdomain} end do
      device = device_fixture()
      assert Devices.get_device_with_mqtt_info(device.id) == {:ok, device, :nxdomain}
    end

    test "get_device_with_mqtt_info/1 returns nil if no device with given id" do
      assert Devices.get_device_with_mqtt_info(777_777_777) == {:error, :not_found}
    end
  end

  describe "get_extraction_series_by_client_ids" do
    test_with_mock "get_extraction_series_by_client_ids/1 returns the extraction series with given client_ids",
                   InfluxdbConn,
                   config: fn :database -> @influx_db_name end,
                   query: fn _, _ -> @influxdb_resp end do
      device = device_fixture()

      assert Devices.get_extraction_series_by_client_ids([device.client_id]) ==
               %{
                 "AAAA1111BBBB2222" => [
                   %{
                     "_time" => "2021-01-01T00:00:00Z",
                     "_value" => 1.0,
                     "client_id" => "AAAA1111BBBB2222",
                     "session_id" => "CCCC3333DDDD4444"
                   }
                 ]
               }
    end

    test_with_mock "get_extraction_series_by_client_ids/1 returns error if no influxdb connection",
                   InfluxdbConn,
                   config: fn :database -> @influx_db_name end,
                   query: fn _, _ -> {:error, :nxdomain} end do
      device = device_fixture()

      assert Devices.get_extraction_series_by_client_ids([device.client_id]) ==
               {:error, :nxdomain}
    end

    test_with_mock "get_extraction_series_by_client_ids/1 returns empty map if no device with given client_ids",
                   InfluxdbConn,
                   config: fn :database -> @influx_db_name end,
                   query: fn _, _ -> [] end do
      assert Devices.get_extraction_series_by_client_ids(["some client_id"]) ==
               %{}
    end
  end

  test "create_device/1 with valid data creates a device" do
    valid_attrs = %{
      firmware_version: "some firmware_version",
      model: "some model",
      owner: "some owner",
      serial_number: "some serial_number",
      client_id: "AAAA1111BBBB2222"
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
    assert {:ok, device} == Devices.get_device(device.id)
  end

  test "delete_device/1 deletes the device" do
    device = device_fixture()
    assert {:ok, %Device{}} = Devices.delete_device(device)
    assert {:error, :not_found} == Devices.get_device(device.id)
  end

  test "change_device/1 returns a device changeset" do
    device = device_fixture()
    assert %Ecto.Changeset{} = Devices.change_device(device)
  end
end
