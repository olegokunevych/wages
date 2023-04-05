defmodule Wages.Broadway do
  @moduledoc """
  Broadway module for Wages.
  """
  use Broadway

  require Logger

  alias Broadway.Message
  alias Wages.Influxdb.Connection
  alias Wages.Mqtt.Processor

  def start_link(opts) do
    Broadway.start_link(__MODULE__, opts)
  end

  @impl Broadway
  def handle_message(_, message, _context) do
    Message.put_batcher(message, :coffee_extractor)
  end

  @impl Broadway
  def handle_batch(:coffee_extractor, messages, batch_info, _context) do
    Logger.info("Batch info: #{inspect(batch_info)}")

    messages = Enum.map(messages, &Processor.process_message/1)

    messages
    |> Enum.map(& &1.data)
    |> Connection.write()

    # messages |> Enum.map(&Message.ack_immediately/1)
    messages
  end
end
