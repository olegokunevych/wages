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
    |> integer(4)
    |> ignore(string("-"))
    |> integer(2)
    |> ignore(string("-"))
    |> integer(2)
    |> ignore(string(" "))
    |> integer(2)
    |> ignore(string(":"))
    |> integer(2)
    |> ignore(string(":"))
    |> integer(2)
    |> ignore(string("."))
    |> integer(min: 2, max: 6)
    |> ignore(optional(string("Z")))
    |> reduce({__MODULE__, :parse_tstamp, [""]})
    |> unwrap_and_tag(:tstamp)

  mqtt = client_id |> concat(value) |> concat(tstamp) |> eos()

  defparsec(:parse, mqtt)

  def parse_float([integer, decimal], _) do
    String.to_float("#{integer}" <> "." <> "#{decimal}")
  end

  def parse_tstamp([year, month, day, hour, minute, second, millisecond], _) do
    with {:ok, date} <- Date.new(year, month, day),
         {:ok, time} <- Time.new(hour, minute, second, millisecond) do
      DateTime.new!(date, time, "Etc/UTC")
    end
  end
end
