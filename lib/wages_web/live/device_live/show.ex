defmodule WagesWeb.DeviceLive.Show do
  use WagesWeb, :live_view

  alias Wages.Devices

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    case Devices.get_device_with_mqtt_info(id) do
      {:ok, device, extractions} ->
        {:noreply,
         socket
         |> assign(:page_title, page_title(socket.assigns.live_action))
         |> assign(:device, device)
         |> assign(:extractions, extractions)}

      _error ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({WagesWeb.DeviceLive.FormComponent, {:saved, device}}, socket) do
    {:noreply, socket |> assign(:device, device)}
  end

  defp page_title(:show), do: "Show Device"
  defp page_title(:edit), do: "Edit Device"
end
