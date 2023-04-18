import Config

config :logger, level: String.to_atom(System.get_env("LOG_LEVEL") || "info")

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/wages start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :wages, WagesWeb.Endpoint, server: true
end

if config_env() == :prod do
  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :wages, Wages.Repo,
    # ssl: true,
    username: System.get_env("POSTGRES_USER") || "postgres",
    password: System.get_env("POSTGRES_PASSWORD") || "postgres",
    hostname: System.get_env("POSTGRES_HOST") || "postgres.wages-dev.svc.cluster.local",
    database: System.get_env("POSTGRES_DB") || "wages_prod",
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_SERVER_HOST") || "localhost"
  port = String.to_integer(System.get_env("SERVICE_PORT") || "4000")
  path = System.get_env("SERVICE_PATH") || "/wages"

  check_origin = case System.get_env("CHECK_ORIGIN") do
    nil -> :conn
    _ -> [_]
  end

  config :wages, WagesWeb.Endpoint,
    url: [host: host, port: port, path: path],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    server: true,
    check_origin: check_origin

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :wages, WagesWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :wages, WagesWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :wages, Wages.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :wages, Wages.Broadway,
    name: Wages.Broadway,
    producer: [
      module: {
        BroadwayRabbitMQ.Producer,
        on_failure: :reject_and_requeue_once,
        on_success: :ack,
        buffer_size: String.to_integer(System.get_env("BROADWAY_PRODUCER_BUFFER_SIZE") || "100"),
        backoff_min: String.to_integer(System.get_env("BROADWAY_PRODUCER_BACKOFF_MIN") || "0"),
        backoff_max: String.to_integer(System.get_env("BROADWAY_PRODUCER_BACKOFF_MAX") || "100"),
        queue: System.get_env("RABBITMQ_QUEUE") || "wages-events",
        declare: [durable: true],
        bindings: [{"amq.topic", [routing_key: "wages.*"]}],
        connection: [
          username: System.get_env("RABBITMQ_USER") || "guest",
          password: System.get_env("RABBITMQ_PASSWORD") || "guest",
          host: System.get_env("RABBITMQ_HOST") || "rabbitmq-amqp.wages-dev.svc.cluster.local",
          port: String.to_integer(System.get_env("RABBITMQ_PORT") || "30672")
        ],
        qos: [
          # See "Back-pressure and `:prefetch_count`" section
          prefetch_count: String.to_integer(System.get_env("BROADWAY_QOS_PREFETCH_COUNT") || "16")
        ]
      },
      concurrency: String.to_integer(System.get_env("BROADWAY_CONCURRENCY") || "16")
    ],
    processors: [
      default: [
        concurrency: String.to_integer(System.get_env("BROADWAY_PROCESSORS_CONCURRENCY") || "8"),
        min_demand: String.to_integer(System.get_env("BROADWAY_PROCESSORS_MIN_DEMAND") || "1"),
        max_demand: String.to_integer(System.get_env("BROADWAY_PROCESSORS_MAX_DEMAND") || "1000")
      ]
    ],
    batchers: [
      coffee_extractor: [
        concurrency: String.to_integer(System.get_env("BROADWAY_BATCHERS_CONCURRENCY") || "8"),
        batch_size: String.to_integer(System.get_env("BROADWAY_BATCHERS_BATCH_SIZE") || "1000"),
        batch_timeout:
          String.to_integer(System.get_env("BROADWAY_BATCHERS_BATCH_TIMEOUT") || "10000")
      ],
      default: []
    ]

  # ,
  # TODO Partition for ordering guarantee
  # partition_by: fn (msg) -> msg.data.client_id end
end

# Configure InfluxDB
config :wages, Wages.Influxdb.Connection,
  auth: [method: :token, token: System.get_env("INFLUXDB_TOKEN")],
  database: System.get_env("INFLUXDB_BUCKET") || "wages",
  org: "wages",
  host: System.get_env("INFLUXDB_HOST") || "influxdb.wages-dev.svc.cluster.local",
  port: String.to_integer(System.get_env("INFLUXDB_PORT") || "8086"),
  scheme: "http"
