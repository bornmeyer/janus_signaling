defmodule Janus.SocketSupervisor do
  use Supervisor

  def start_link(url) do
    Supervisor.start_link(__MODULE__, url, name: __MODULE__)
  end

  @impl true
  def init(url) do
    children = [
      Janus.KeepAlivePulse.child_spec(),
      Janus.DispatcherSetup.child_spec(),
      Janus.Dispatcher.child_spec(url),
      Janus.Socket.child_spec(url),
    ]
    Supervisor.init(children, strategy: :one_for_all)
  end
end
