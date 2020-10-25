defmodule Janus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(type, args) do
    ip = Application.get_env(:general, :ip) || "192.168.178.33"
    port = Application.get_env(:general, :port) || 8188
    url = "ws://#{ip}:#{port}"
    children = [
      Janus.Socket.child_spec(url),
      Janus.Dispatcher.child_spec(url),
      {
        Janus.StreamSupervisor, []
      },
      Janus.StreamManager,
      Janus.RoomManager.child_spec(),
      {
        Registry, [keys: :unique, name: :stream_registry]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Janus.Supervisor]
    result = Supervisor.start_link(children, opts)
    setup()
    result
  end

  defp setup do
      %{"data" => %{"id" => session_id}, "janus" => "success"} = Janus.Dispatcher.send_message(Janus.Messages.create_session_message)
      Janus.Dispatcher.set_data(:remote_session_id, session_id)
      %{"data" => %{"id" => handle_id}, "janus" => "success"} = Janus.Dispatcher.send_message(Janus.Messages.create_attach_message(session_id))
      Janus.Dispatcher.set_data(:handle_id, handle_id)
      Janus.Dispatcher.queue_keep_alive(session_id)
  end
end
