defmodule General.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: General.Router,
        options: [
          dispatch: dispatch(),
          port: 4000
        ]
      ),
      Registry.child_spec(
        keys: :duplicate,
        name: Registry.General
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: General.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
        [
          {:_, General.SocketHandler, []},
          #{:_, Plug.Cowboy.Handler, {General.Router, []}}
        ]
      }
    ]
  end

end
