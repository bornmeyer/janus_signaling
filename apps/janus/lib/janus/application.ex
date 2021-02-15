defmodule Janus.Application do
  require Logger

  def start(_type, _args) do
    ip = Application.get_env(:general, :ip) || "192.168.178.33"
    port = Application.get_env(:general, :port) || 8188
    url = "ws://#{ip}:#{port}"
    children = [
      #Janus.Dispatcher.child_spec(url),
      #Janus.Socket.child_spec(url),

      {
        Janus.StreamSupervisor, []
      },
      Janus.StreamManager,
      Janus.PluginManager,
      Janus.RoomManager.child_spec(),
      {
        Registry, [keys: :unique, name: :stream_registry]
      },
      {
        Janus.SocketSupervisor, [url]
      },
    ]

    opts = [strategy: :one_for_all, name: Janus.Supervisor]
    result = Supervisor.start_link(children, opts)
    result
  end


end
