defmodule Wages.Cache do
  @moduledoc """
  The Cache module.
  """
  use Nebulex.Cache,
    otp_app: :wages,
    adapter: Nebulex.Adapters.Local
end
