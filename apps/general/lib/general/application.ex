defmodule General.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    ip = Application.get_env(:general, :ip) || "192.168.178.33"
    port = Application.get_env(:general, :port) || 8188
    Logger.info("ws://#{ip}:#{port}")
    children = [
      #General.JanusSocket.child_spec("ws://#{ip}:#{port}"),
      General.Dispatcher.child_spec("ws://#{ip}:#{port}"),
      General.ClientSideSupervisor.child_spec(ip, port)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: General.Supervisor]
    Supervisor.start_link(children, opts)
  end

 

 
end
