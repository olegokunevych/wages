defmodule WagesWeb.DeviceLiveTest do
  use WagesWeb.ConnCase

  import Mock
  import Phoenix.LiveViewTest
  import Wages.DevicesFixtures

  alias Wages.Devices
  alias Wages.Influxdb.Connection, as: InfluxdbConn

  @create_attrs %{
    firmware_version: "some firmware_version",
    model: "some model",
    owner: "some owner",
    serial_number: "some serial_number",
    client_id: "AAAA1111BBBB2222"
  }
  @update_attrs %{
    firmware_version: "some updated firmware_version",
    model: "some updated model",
    owner: "some updated owner",
    serial_number: "some updated serial_number",
    client_id: "CCCC3333DDDD4444"
  }
  @invalid_attrs %{client_id: nil}
  @influx_db_name "wages_test"

  defp create_device(_) do
    device = device_fixture()
    %{device: device}
  end

  setup_with_mocks(
    [
      {InfluxdbConn, [],
       [
         query: fn _, _ ->
           [
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
         end,
         config: fn :database -> @influx_db_name end
       ]}
    ],
    context
  ) do
    {:ok, context}
  end

  describe "Index" do
    setup [:create_device]

    test "lists all devices", %{conn: conn, device: device} do
      {:ok, _index_live, html} = live(conn, ~p"/devices")

      assert html =~ "Listing Devices"
      assert html =~ device.firmware_version
    end

    test "saves new device", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/devices")

      assert index_live |> element("a", "New Device") |> render_click() =~
               "New Device"

      assert_patch(index_live, ~p"/devices/new")

      assert index_live
             |> form("#device-form", device: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#device-form", device: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/devices")

      html = render(index_live)
      assert html =~ "Device created successfully"
      assert html =~ "some firmware_version"
    end

    test "updates device in listing", %{conn: conn, device: device} do
      {:ok, index_live, _html} = live(conn, ~p"/devices")

      assert index_live |> element("#devices-#{device.id} a", "Edit") |> render_click() =~
               "Edit Device"

      assert_patch(index_live, ~p"/devices/#{device}/edit")

      assert index_live
             |> form("#device-form", device: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#device-form", device: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/devices")

      html = render(index_live)
      assert html =~ "Device updated successfully"
      assert html =~ "some updated firmware_version"
    end

    test "deletes device in listing", %{conn: conn, device: device} do
      {:ok, index_live, _html} = live(conn, ~p"/devices")

      assert index_live |> element("#devices-#{device.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#devices-#{device.id}")
    end
  end

  describe "Show" do
    setup [:create_device]

    test "displays device", %{conn: conn, device: device} do
      {:ok, _show_live, html} = live(conn, ~p"/devices/#{device}")

      assert html =~ "Show Device"
      assert html =~ device.firmware_version
    end

    test "updates device within modal", %{conn: conn, device: device} do
      {:ok, show_live, _html} = live(conn, ~p"/devices/#{device}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Device"

      assert_patch(show_live, ~p"/devices/#{device}/show/edit")

      assert show_live
             |> form("#device-form", device: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#device-form", device: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/devices/#{device}")

      html = render(show_live)
      assert html =~ "Device updated successfully"
      assert html =~ "some updated firmware_version"
    end

    test "doesn't display influxdb data when Influxdb is not available", %{
      conn: conn,
      device: device
    } do
      with_mock InfluxdbConn, [],
        config: fn :database -> @influx_db_name end,
        query: fn _, _ -> {:error, :nxdomain} end do
        {:ok, _show_live, html} = live(conn, ~p"/devices/#{device}")

        assert html =~ "Show Device"
        assert html =~ device.firmware_version
      end
    end

    test "doesn't display device info when unexpected error hapenned", %{
      conn: conn,
      device: device
    } do
      with_mock Devices, [], get_device_with_mqtt_info: fn _ -> {:error, :not_found} end do
        {:ok, _show_live, html} = live(conn, ~p"/devices/#{device}")

        assert html =~ "Device not found"
      end
    end
  end
end
