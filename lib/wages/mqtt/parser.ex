defmodule Wages.Mqtt.Parser do
  @moduledoc """
  The `Wages.Mqtt.Parser` module provides a parser for MQTT messages.
  """
  import NimbleParsec

  separator = string(";")

  client_id =
    ignore(string("c_id="))
    |> utf8_string([], 32)
    |> unwrap_and_tag(:client_id)
    |> ignore(separator)

  session_id =
    ignore(string("s_id="))
    |> utf8_string([], 36)
    |> unwrap_and_tag(:session_id)
    |> ignore(separator)

  value =
    ignore(string("val="))
    |> integer(min: 1, max: 10)
    |> ignore(string("."))
    |> integer(min: 1, max: 10)
    |> reduce({__MODULE__, :parse_float, [""]})
    |> unwrap_and_tag(:value)
    |> ignore(separator)

  tstamp =
    ignore(string("ts="))
    |> integer(min: 9)
    |> reduce({__MODULE__, :convert_to_nanoseconds, [""]})
    |> unwrap_and_tag(:tstamp)

  mqtt = client_id |> concat(session_id) |> concat(value) |> concat(tstamp) |> eos()

  defparsec(:parse, mqtt)

  def parse_float([integer, decimal], _) do
    String.to_float("#{integer}" <> "." <> "#{decimal}")
  end

  def convert_to_nanoseconds([tstamp], _) do
    tstamp |> to_string() |> String.pad_trailing(19, "0") |> String.to_integer()
  end
end
