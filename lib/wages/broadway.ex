defmodule Wages.Broadway do
  @moduledoc """
  Broadway module for Wages.
  """
  use Broadway

  require Logger

  def start_link(opts) do
    Broadway.start_link(__MODULE__, opts)
  end

  @impl Broadway
  def handle_message(_, message, _context) do
    # Broadway.Message.ack_immediately(message)
    :ok = process_message(message)
    message
  end

  defp process_message(message) do
    Logger.debug("Received message: #{inspect(message)}")
    :ok
  end
end
