defmodule Wages.Mqtt do
  alias Wages.Mqtt.Parser

  defstruct [:client_id, :value, :tstamp]

  def new(binary) when is_binary(binary) do
    case Parser.parse(binary) do
      {:ok, res, "", _, _, _} -> {:ok, struct!(__MODULE__, res)}
      {:error, reason, _, _, _, _} -> {:error, reason}
    end
  end
end
