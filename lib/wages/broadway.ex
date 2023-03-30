defmodule Wages.Broadway do
  @moduledoc """
  Broadway module for Wages.
  """
  use Broadway

  require Logger

  alias Wages.{Devices, Mqtt}
  alias Wages.Influxdb.{Connection, MqttSeries}

  def start_link(opts) do
    Broadway.start_link(__MODULE__, opts)
  end

  @impl Broadway
  def handle_message(_, message, _context) do
    # Broadway.Message.ack_immediately(message)
    # :ok = process_message(message)
    message
  end

  @impl Broadway
  def handle_batch(_, messages, _, _) do
    # IO.inspect(messages, label: "messages")
    messages |> Enum.map(&process_message/1)
    # messages |> Enum.map(&Broadway.Message.ack_immediately/1)
    # messages
  end

  defp process_message(message) do
    {:ok, res} = Mqtt.new(message.data)
    Logger.debug("Received message: #{inspect(res)}")

    with {:error, :not_found} <- Devices.get_device_by_client_id(res.client_id) do
      Logger.info("Creating new device with client_id: #{res.client_id}")
      Devices.create_device(%{client_id: res.client_id})
    end

    :ok =
      Connection.write(%MqttSeries{
        fields: %MqttSeries.Fields{value: res.value},
        tags: %MqttSeries.Tags{client_id: res.client_id}
      })

    :ok
  end
end
