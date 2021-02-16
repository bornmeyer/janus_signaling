defmodule Janus.KeepAlivePulse do
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

  def init(_args) do
    Process.flag(:trap_exit, true)
    {:ok, %{:timer_refs => []}}
  end

  def handle_cast({:queue_keep_alive, session_id, interval}, %{:timer_refs => current_timer_refs} = state) do
    timer_ref = Process.send_after(Janus.Dispatcher, {:keep_alive, session_id}, interval * 1000)
    kill_timer_refs(current_timer_refs)
    state = state |> Map.update(:timer_refs, nil, fn _ -> [timer_ref] end)
    {:noreply, state}
  end

  def terminate(_reason, %{:timer_refs => timer_refs}) do
    kill_timer_refs(timer_refs)
  end

  defp kill_timer_refs(timer_refs) do
    for current <- timer_refs  do
      Process.cancel_timer(current, async: false, info: false)
    end
  end

  def queue_keep_alive(session_id, interval \\ 15) do
    GenServer.cast(__MODULE__, {:queue_keep_alive, session_id, interval})
  end
end
