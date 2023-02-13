Application.put_env(:sample, SamplePhoenix.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  server: true,
  live_view: [signing_salt: "aaaaaaaa"],
  secret_key_base: String.duplicate("a", 64)
)

Application.put_env(:phoenix, :json_library, Jason)

Mix.install([
  {:plug_cowboy, "~> 2.5"},
  {:jason, "~> 1.0"},
  {:phoenix, "~> 1.6.15", override: true},
  {:phoenix_live_view, "~> 0.18.13"}
])

defmodule SamplePhoenix.ErrorView do
  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule SamplePhoenix.TestComponent do
  use Phoenix.Component, global_prefixes: ~w(x-)

  attr :rest, :global

  def test_component(assigns) do
    ~H"""
    <div {@rest}>
      This is a test
    </div>
    """
  end

  attr :thing, :string, required: true

  def nested_component(assigns) do
    ~H"""
    <div>
      <%= @thing %>
      <.test_component x-data="{}" />
    </div>
    """
  end
end

defmodule SamplePhoenix.SampleLive do
  use Phoenix.LiveView, layout: {__MODULE__, :live}

  # Setting the global_prefixes on the caller fixes the compile time warning:
  # use Phoenix.LiveView, layout: {__MODULE__, :live}, global_prefixes: ~w(x-)

  import SamplePhoenix.TestComponent

  def render("live.html", assigns) do
    ~H"""
    <script src="https://cdn.jsdelivr.net/npm/phoenix@1.16.15/priv/static/phoenix.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/phoenix_live_view@0.18.13/priv/static/phoenix_live_view.min.js"></script>
    <script>
      let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket)
      liveSocket.connect()
    </script>
    <style>
      * { font-size: 1.1em; }
    </style>
    <%= @inner_content %>
    """
  end

  def render(assigns) do
    ~H"""
    <.test_component x-data="{}" />

    <.nested_component thing="test" />
    """
  end
end

defmodule Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/", SamplePhoenix do
    pipe_through(:browser)

    live("/", SampleLive, :index)
  end
end

defmodule SamplePhoenix.Endpoint do
  use Phoenix.Endpoint, otp_app: :sample
  socket("/live", Phoenix.LiveView.Socket)
  plug(Router)
end
