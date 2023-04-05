defmodule Wages.Mqtt do
  @moduledoc """
  The `Wages.Mqtt` module provides a struct for parsing MQTT messages.
  """

  alias Wages.Mqtt.Parser

  defstruct [:client_id, :session_id, :value, :tstamp]

  @doc """
  Parses a binary string into a struct.

  Examples:

      iex> Wages.Mqtt.new("c_id=5D5DC50FF413751125FC7DA42C008048;s_id=8060f5c4-cc37-433d-9573-a4650555f2a9;val=6.3;ts=1680683795000")
      {:ok, %Wages.Mqtt{client_id: "5D5DC50FF413751125FC7DA42C008048", session_id: "8060f5c4-cc37-433d-9573-a4650555f2a9", value: 6.3, tstamp: 1680683795000000000}}

      iex> {:error, "expected string" <> _} = Wages.Mqtt.new("invalid_binary_string")

  """
  @spec new(binary()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def new(binary) when is_binary(binary) do
    case Parser.parse(binary) do
      {:ok, res, "", _, _, _} -> {:ok, struct!(__MODULE__, res)}
      {:error, reason, _, _, _, _} -> {:error, reason}
    end
  end
end
