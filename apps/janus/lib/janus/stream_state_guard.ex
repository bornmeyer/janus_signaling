defmodule Janus.StreamStateGuard do
  use GenStateMachine

  def child_spec(id, stream) do
    %{

    }
  end

  def init(state) do
    {:ok, state}
  end

  def start_link(state) do
    GenStateMachine.start_link(__MODULE__, state, name: via_tuple(state.id))
  end

  def handle_event({:call, _from}, {:advance_stream, command}, :publish, data) do
    {:next_state, :start_publish, data}
  end

  def handle_event({:call, _from}, {:advance_stream, command}, :start_publish, data) do
    {:next_state, :play, data}
  end

  def handle_event({:call, _from}, {:advance_stream, command}, :play, data) do
    {:next_state, :start_play, data}
  end

  def handle_event({:call, _from}, {:advance_stream, command}, :start_play, data) do

  end

  defp via_tuple(id) do
    {:via, Registry, {:stream_guard_registry, id}}
  end
end
