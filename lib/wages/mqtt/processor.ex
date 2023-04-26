defmodule Wages.Mqtt.Processor do
  @moduledoc """
  Processor for MQTT messages.
  """
  require Logger

  alias Broadway.Message
  alias Wages.{Devices, Mqtt}
  alias Wages.Influxdb.MqttSeries
  alias WagesWeb.Endpoint

  @spec process_message(Message.t()) :: Message.t()
  def process_message(message) do
    with {:ok, res} <- Mqtt.new(message.data),
         {:ok, _device} <- handle_device(res.client_id),
         :ok <- broadcast_data(res) do
      Logger.debug("Received message: #{inspect(res)}")

      data = %MqttSeries{
        fields: %MqttSeries.Fields{value: res.value},
        tags: %MqttSeries.Tags{client_id: res.client_id, session_id: res.session_id},
        timestamp: res.tstamp
      }

      Message.put_data(message, data)
    else
      {:error, reason} ->
        Logger.error(
          "Error processing message: #{inspect(message.data)} Reason: #{inspect(reason)}"
        )

        Message.failed(message, reason)
    end
  end

  defp handle_device(client_id) do
    with {:error, :not_found} <- Devices.get_device_by_client_id(client_id) do
      Logger.info("Creating new device with client_id: #{client_id}")
      Devices.create_device(%{client_id: client_id})
    end
  end

  defp broadcast_data(data) do
    Logger.debug("Broadcasting data: #{inspect(data)}")
    Endpoint.broadcast("extractions", "new-point", data)
  end
end
