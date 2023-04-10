import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :wages, Wages.Repo,
  username: System.get_env("DATABASE_USER", "postgres"),
  password: System.get_env("DATABASE_PASSWORD", "postgres"),
  database:
    System.get_env("DATABASE_NAME", "wages_#{Mix.env()}_#{System.get_env("MIX_TEST_PARTITION")}"),
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :wages, WagesWeb.Endpoint,
  url: [host: "localhost", path: "/"],
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "AI0HIBobH7H7vtXPJu2IJsRekv3odHBuHLz5TIk5d3N/eFrlhRF7B+eO9TEIMLLl",
  server: false

# In test we don't send emails.
config :wages, Wages.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :wages, Wages.Broadway,
  name: Wages.Broadway,
  producer: [
    module: {Broadway.DummyProducer, []}
  ],
  processors: [
    default: []
  ]
