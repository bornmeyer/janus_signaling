defmodule Janus.Application do
  require Logger

  def start(_type, _args) do
    ip = Application.get_env(:general, :ip) || "192.168.178.33"
    port = Application.get_env(:general, :port) || 8188
    url = "ws://#{ip}:#{port}"
    children = [
      {
        Registry, [keys: :unique, name: :stream_registry]
      },
      {
        Registry, [keys: :unique, name: :stream_state_guard_registry]
      },
      {
        Registry, [keys: :unique, name: :stream_infrastructure_registry]
      },
      {
        Registry, [keys: :unique, name: :stream_configuration_registry]
      },
      {
        Janus.SocketSupervisor, [url]
      },
      {
        Janus.StreamSupervisor, []
      },
      Janus.StreamManager,
      Janus.PluginManager,
      Janus.RoomManager.child_spec(),

    ]

    opts = [strategy: :one_for_one, name: Janus.Supervisor]
    Supervisor.start_link(children, opts)
  end


end
