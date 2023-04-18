defmodule WagesWeb.DeviceLive.Index do
  use WagesWeb, :live_view

  alias Wages.Devices
  alias Wages.Devices.Device

  @impl true
  def mount(params, _session, socket) do
    page = Devices.list_devices(params)

    socket =
      socket
      |> assign(:page, page)
      |> stream(:devices, [])

    {:ok, socket}
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

  defp apply_action(socket, :index, params) do
    page = Devices.list_devices(params)

    page.entries
    |> Enum.with_index()
    |> handle_pagination(socket)
    |> assign(:page_title, "Listing Devices")
    |> assign(:page, page)
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

  defp handle_pagination(entries, socket) do
    Enum.reduce(entries, socket, fn {el, ind}, socket ->
      case Enum.at(socket.assigns.page.entries, ind) do
        nil -> socket
        old_el -> socket |> stream_delete(:devices, old_el)
      end
      |> stream_insert(:devices, el)
    end)
  end
end
