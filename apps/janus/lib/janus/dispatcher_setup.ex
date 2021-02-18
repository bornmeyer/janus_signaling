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
    Janus.Messages.create_session_message
    |> Janus.Dispatcher.send_message
    |> set_data(:remote_session_id)
    |> Janus.Messages.create_attach_message
    |> Janus.Dispatcher.send_message
    |> set_data(:handle_id)

    Janus.Dispatcher.get_data(:remote_session_id)
    |> Janus.KeepAlivePulse.queue_keep_alive
    {:noreply, state}
  end

  defp set_data(%{"data" => %{"id" => data}, "janus" => "success"}, key) do
    Janus.Dispatcher.set_data(key, data)
    data
  end

  def setup do
    GenServer.cast(__MODULE__, :setup)
  end
end
