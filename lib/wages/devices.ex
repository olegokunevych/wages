defmodule Wages.Devices do
  @moduledoc """
  The Devices context.
  """

  use Nebulex.Caching

  import Ecto.Query, warn: false

  alias Wages.Cache
  alias Wages.Repo

  alias Wages.Devices.Device
  alias Wages.Influxdb.ConnectionRead, as: InfluxdbConn

  @ttl :timer.hours(1)

  @doc """
  Returns the list of devices.

  ## Examples

      iex> list_devices()
      %Scrivener.Page{entries: [%Device{}, ...]}

  """
  @spec list_devices(map()) :: Scrivener.Page.t()
  def list_devices(params \\ %{}) do
    Repo.paginate(Device, params)
  end

  @doc """
  Returns the list of devices with MQTT info.

  ## Examples

      iex> list_devices_with_mqtt_info()
      %Scrivener.Page{entries: [%Device{}, ...]}

  """
  @spec list_devices_with_mqtt_info(map()) :: Scrivener.Page.t()
  def list_devices_with_mqtt_info(params \\ %{}) do
    %Scrivener.Page{entries: _devices} = list_devices(params)

    # InfluxdbConn.query(
    #   """
    #     from(bucket: "#{InfluxdbConn.bucket()}")

    #   """
    # )
  end

  @doc """
  Gets a single device.

  Raises `Ecto.NoResultsError` if the Device does not exist.

  ## Examples

      iex> get_device(123)
      {:ok, %Device{id: 123}}

      iex> get_device(456)
      {:error, :not_found}

  """
  @decorate cacheable(
              cache: Cache,
              key: {Device, id},
              opts: [ttl: @ttl],
              match: &match_retrieve/1
            )
  @spec get_device(integer()) :: {:ok, Device.t()} | {:error, :not_found}
  def get_device(id) do
    case Repo.get(Device, id) do
      nil -> {:error, :not_found}
      device -> {:ok, device}
    end
  end

  @doc """
  Gets a single device by client_id.
  """
  @decorate cacheable(
              cache: Cache,
              key: {Device, client_id},
              opts: [ttl: @ttl],
              match: &match_retrieve/1
            )
  @spec get_device_by_client_id(String.t()) :: {:ok, Device.t()} | {:error, :not_found}
  def get_device_by_client_id(client_id) do
    device = Repo.one(from(d in Device, where: d.client_id == ^client_id))

    case device do
      nil -> {:error, :not_found}
      _ -> {:ok, device}
    end
  end

  @spec get_device_with_mqtt_info(integer()) ::
          {:ok, Device.t(), map() | atom()} | {:error, :not_found}
  def get_device_with_mqtt_info(id) do
    with {:ok, device} <- get_device(id),
         {_, mqtt_info} <- get_mqtt_info(device) do
      {:ok, device, mqtt_info}
    else
      error -> error
    end
  end

  @spec get_extraction_series_by_client_ids([integer()]) :: map() | {:error, :nxdomain}
  def get_extraction_series_by_client_ids(client_ids) do
    with {:ok, measurements} <- do_summary_query(client_ids) do
      Enum.map(measurements, fn measurement ->
        Map.take(measurement, ["_time", "_value", "session_id", "client_id"])
      end)
      |> Enum.group_by(&Map.get(&1, "client_id"))
    end
  end

  @doc """
  Creates a device.

  ## Examples

      iex> create_device(%{field: value})
      {:ok, %Device{}}

      iex> create_device(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_device(map()) :: {:ok, Device.t()} | {:error, Ecto.Changeset.t()}
  def create_device(attrs \\ %{}) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a device.

  ## Examples

      iex> update_device(device, %{field: new_value})
      {:ok, %Device{}}

      iex> update_device(device, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @decorate cache_put(
              cache: Cache,
              key: {Device, Integer.to_string(device.id)},
              match: &match_update/1,
              opts: [ttl: @ttl]
            )
  @spec update_device(Device.t(), map()) :: {:ok, Device.t()} | {:error, Ecto.Changeset.t()}
  def update_device(%Device{} = device, attrs) do
    device
    |> Device.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a device.

  ## Examples

      iex> delete_device(device)
      {:ok, %Device{}}

      iex> delete_device(device)
      {:error, %Ecto.Changeset{}}

  """
  @decorate cache_evict(cache: Cache, key: {Device, device.id})
  @spec delete_device(Device.t()) :: {:ok, Device.t()} | {:error, Ecto.Changeset.t()}
  def delete_device(%Device{} = device) do
    Repo.delete(device)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking device changes.

  ## Examples

      iex> change_device(device)
      %Ecto.Changeset{data: %Device{}}

  """
  @spec change_device(Device.t(), map()) :: Ecto.Changeset.t()
  def change_device(%Device{} = device, attrs \\ %{}) do
    Device.changeset(device, attrs)
  end

  defp match_retrieve({:ok, _value}), do: true
  defp match_retrieve({:error, _}), do: false

  defp match_update({:ok, updated}), do: {true, {:ok, updated}}
  defp match_update({:error, _}), do: false

  defp get_mqtt_info(device) do
    case do_query(device.client_id) do
      {:ok, measurements} -> {:ok, get_grouped_by_session(measurements)}
      error -> error
    end
  end

  defp do_summary_query(client_ids) do
    """
      from(bucket: "#{InfluxdbConn.config(:database)}")
      |> range(start: -30d)
      |> filter(fn: (r) => r["_measurement"] == "wages_meas")
      |> filter(fn: (r) => r["client_id"] == "#{Enum.join(client_ids, "\" or r[\"client_id\"] == \"")}")
      |> aggregateWindow(every: 1s, fn: mean, createEmpty: false)
    """
    |> InfluxdbConn.query(query_language: :flux)
    |> handle_influxdb_response()
  end

  defp do_query(client_id) do
    """
      from(bucket: "#{InfluxdbConn.config(:database)}")
      |> range(start: -30d)
      |> filter(fn: (r) => r["_measurement"] == "wages_meas")
      |> filter(fn: (r) => r["client_id"] == "#{client_id}")
      |> aggregateWindow(every: 1s, fn: mean, createEmpty: false)
    """
    |> InfluxdbConn.query(query_language: :flux)
    |> handle_influxdb_response()
  end

  defp handle_influxdb_response({:error, reason}), do: {:error, reason}

  defp handle_influxdb_response(results) when is_list(results) do
    {:ok, results}
  end

  defp get_grouped_by_session(measurements) do
    Enum.map(measurements, fn measurement ->
      Map.take(measurement, ["_time", "_value", "session_id"])
    end)
    |> Enum.group_by(&Map.get(&1, "session_id"))
  end
end
