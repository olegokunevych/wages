# Wages brief description

This project implements a platform for the Coffee scales to brew coffee at home or in cafes.
It is a `Phoenix LiveView` application that uses a `PostgreSQL` database to store the data about coffee scale devices. Also it uses `InfluxDB` to store the time series data about the coffee extractions (grams of coffee brew extracted at certain amount of time for each device in separate sessions). The incoming data is processed by `Broadway` which consumes data efficiently from `RabbitmMQ`. Incoming messages are using `MQTT protocol`, The MQTT broker is `RabbitMQ` with MQTT plugin. Then Elixir Application parses the MQTT payload using `NimbleParsec` library and stores it to the InfluxDB. At the same time Application uses the data from the `InfluxDB` to display the graphs of the coffee extractions in realtime.

## Implementation notes

### Caching

While implementing and testing the application, I've found out potential bottleneck: when large amount of clients connected, they are hitting the database dramatically. To avoid it, I decided to cache functions from `Devices` context using `Nebulex` library. The cache is configured to use `:local` storage, which means that the cache is stored in the memory of the node. The cache is configured to expire in 1 hour. The cache is used for `Devices.get_device/1` and `Devices.get_device_by_client_id/1` functions. The cache is invalidated when the device is updated or deleted.

### MQTT parsing

The MQTT payload is parsed using `NimbleParsec` library. The parser is defined in `lib/wages/mqtt_parser.ex` file, implemented using `NimbleParsec` combinators. The parser is tested using `ExUnit` library with doctests approach. The typical MQTT message includes following fields: `client_id`, `session_id`, `value`, `tstamp`. The `client_id` is the unique identifier of the device. The `session_id` is the unique identifier of the session. The `value` is the value of the coffee extraction. The `tstamp` is the timestamp of the coffee extraction.

## Dependencies

* Postgresql
* InfluxDB
* RabbitMQ with MQTT plugin
* Coffee scales hardware

## CI/CD

Github Actions are used for CI/CD purposes. The CI/CD pipeline is defined in `.github/workflows/*.yml` files. The CI pipeline is triggered on every push to any branch. The build pipeline is triggered on every push to main branch and on every pull request to main branch. The CI pipeline compiles application, runs the tests, coverage, format checks, etc. The build pipeline builds the docker image and push it to the GHCR image registry.

## Deployment

Kubernetes/Helm approach is used for deployment. The deployment is defined in separate repository and is done to the Kubernetes cluster built from Raspbery Pi 4 and Orange Pi 5 credit card size computers. The deployment is done using `helm` and `kubectl` commands. The deployment is done to the `wages` namespace.

## Configuration

Configuration is done using environment variables. The environment variables are used to configure the Postgresql connection, Influxdb connection, RabbitMQ connection, etc. Sample configuration is provided in `.env.sample` file.

## Known issues

To test javascript websocket connection locally, path to websocket should be changed, in order to do it, replace line:
`let liveSocket = new LiveSocket("/wages/live", Socket, { hooks: LiveViewHooks, params: { _csrf_token: csrfToken } })`
with
`let liveSocket = new LiveSocket("/live", Socket, { hooks: LiveViewHooks, params: { _csrf_token: csrfToken } })`
Repository points websocket connection path to `/wages/live` for Kubernetes deployment approach.
Need to find a way to make this path configurable.

## Testing

The tests are implemented using `ExUnit` library. The tests are located in `test` directory. The tests are run using `mix test` command.

## Development

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000/devices`](http://localhost:4000/devices) from your browser.
