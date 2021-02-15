defmodule Janus.SocketSupervisor do
  use Supervisor
  require Logger

  def start_link(url) do
    Supervisor.start_link(__MODULE__, url, name: __MODULE__)
  end

  @impl true
  def init(url) do
    url |> Logger.info
    children = [
      Janus.Socket.child_spec(url),
      Janus.Dispatcher.child_spec(url),
      Janus.DispatcherSetup
    ]

    result = Supervisor.init(children, strategy: :one_for_all)
    result
  end
end
