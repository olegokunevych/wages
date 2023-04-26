defmodule WagesWeb.DeviceLive.Show do
  use WagesWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias Wages.Devices
  alias WagesWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = Endpoint.subscribe("extractions")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    case Devices.get_device_with_mqtt_info(id) do
      {:ok, device, :nxdomain} ->
        {:noreply, handle_empty_results(socket, device)}

      {:ok, device, :econnrefused} ->
        {:noreply, handle_empty_results(socket, device)}

      {:ok, device, extractions} ->
        {:noreply,
         socket
         |> assign(:page_title, page_title(socket.assigns.live_action))
         |> assign(:device, device)
         |> assign(:extractions, extractions)}

      _error ->
        {:noreply, socket |> assign(:device, nil)}
    end
  end

  @impl true
  def handle_info({WagesWeb.DeviceLive.FormComponent, {:saved, device}}, socket) do
    {:noreply, socket |> assign(:device, device)}
  end

  @impl true
  def handle_info(
        %Broadcast{
          event: "new-point",
          payload: %Wages.Mqtt{
            client_id: client_id,
            session_id: s_id,
            value: value,
            tstamp: tstamp
          }
        },
        socket
      ) do
    case socket.assigns.device.client_id == client_id do
      true ->
        {:noreply,
         push_event(socket, "new-point", %{label: s_id, value: %{val: value, tstamp: tstamp}})}

      false ->
        {:noreply, socket}
    end
  end

  defp page_title(:show), do: "Show Device"
  defp page_title(:edit), do: "Edit Device"

  defp handle_empty_results(socket, device) do
    socket
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(:device, device)
    |> assign(:extractions, [])
  end
end
