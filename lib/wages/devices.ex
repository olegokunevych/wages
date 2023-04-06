defmodule Wages.Devices do
  @moduledoc """
  The Devices context.
  """

  use Nebulex.Caching

  import Ecto.Query, warn: false

  alias Wages.Cache
  alias Wages.Repo

  alias Wages.Devices.Device

  @ttl :timer.hours(1)

  @doc """
  Returns the list of devices.

  ## Examples

      iex> list_devices()
      [%Device{}, ...]

  """
  @spec list_devices() :: [Device.t()]
  def list_devices do
    Repo.all(Device)
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
    device = Repo.one(from d in Device, where: d.client_id == ^client_id)

    case device do
      nil -> {:error, :not_found}
      _ -> {:ok, device}
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
end
