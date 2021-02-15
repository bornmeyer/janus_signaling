defmodule Janus.DispatcherSetup do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call(:setup, _from, state) do
    %{"data" => %{"id" => session_id}, "janus" => "success"} = Janus.Dispatcher.send_message(Janus.Messages.create_session_message)
    Janus.Dispatcher.set_data(:remote_session_id, session_id)
    %{"data" => %{"id" => handle_id}, "janus" => "success"} = Janus.Dispatcher.send_message(Janus.Messages.create_attach_message(session_id))
    Janus.Dispatcher.set_data(:handle_id, handle_id)
    Janus.Dispatcher.queue_keep_alive(session_id)
    {:reply, :ok, state}
  end

  def setup do
    GenServer.call(__MODULE__, :setup)
  end
end
