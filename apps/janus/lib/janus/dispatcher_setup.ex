defmodule Janus.DispatcherSetup do
  use GenServer
  require Logger

  def child_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent
    }
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast(:setup, state) do
    %{"data" => %{"id" => session_id}, "janus" => "success"} = Janus.Dispatcher.send_message(Janus.Messages.create_session_message)
    Janus.Dispatcher.set_data(:remote_session_id, session_id)
    %{"data" => %{"id" => handle_id}, "janus" => "success"} = Janus.Dispatcher.send_message(Janus.Messages.create_attach_message(session_id))
    Janus.Dispatcher.set_data(:handle_id, handle_id)
    Janus.KeepAlivePulse.queue_keep_alive(session_id)
    {:noreply, state}
  end

  def setup do
    GenServer.cast(__MODULE__, :setup)
  end
end
