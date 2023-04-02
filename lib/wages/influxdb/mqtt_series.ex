defmodule Wages.Influxdb.MqttSeries do
  @moduledoc """
  InfluxDB series for MQTT messages.
  """

  use Instream.Series

  series do
    measurement("wages_meas")

    tag(:client_id)
    tag(:session_id)

    field :value
  end
end
