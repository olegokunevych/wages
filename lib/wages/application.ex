defmodule Wages.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias WagesWeb.Endpoint

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      WagesWeb.Telemetry,
      # Start the Ecto repository
      Wages.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Wages.PubSub},
      # Start Finch
      {Finch, name: Wages.Finch},
      # Start the Endpoint (http/https)
      WagesWeb.Endpoint,
      {Wages.Broadway, Application.get_env(:wages, Wages.Broadway)}
      # Start a worker by calling: Wages.Worker.start_link(arg)
      # {Wages.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wages.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
