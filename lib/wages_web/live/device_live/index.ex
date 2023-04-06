defmodule WagesWeb.DeviceLive.Index do
  use WagesWeb, :live_view

  alias Wages.Devices
  alias Wages.Devices.Device

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :devices, Devices.list_devices())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    {:ok, device} = Devices.get_device(id)

    socket
    |> assign(:page_title, "Edit Device")
    |> assign(:device, device)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Device")
    |> assign(:device, %Device{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Devices")
    |> assign(:device, nil)
  end

  @impl true
  def handle_info({WagesWeb.DeviceLive.FormComponent, {:saved, device}}, socket) do
    {:noreply, stream_insert(socket, :devices, device)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    with {:ok, device} <- Devices.get_device(id),
         {:ok, _} <- Devices.delete_device(device) do
      {:noreply, stream_delete(socket, :devices, device)}
    else
      _ -> {:noreply, socket}
    end
  end
end
