defmodule Janus.StreamStateGuard do
  use GenStateMachine

  def child_spec(stream_id) do
    %{
      id: stream_id,
      start: {__MODULE__, :start_link, [%{stream_id: stream_id}]},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end

  def start_link(state) do
    GenStateMachine.start_link(__MODULE__, {:publish, state}, name: via_tuple(state.stream_id))
  end


  def handle_event({:call, from}, {:advance_stream, command, state, web_socket, [stream_id: stream_id]}, :publish, data) do
    {:ok, plugin} = Janus.PluginManager.new(state.participant_id, state.room_id)
    stream = Janus.StreamSupervisor.start_child(stream_id, state.participant_id, state.room_id, web_socket, plugin.handle_id)
    Janus.StreamManager.add_stream(stream, state.participant_id)
    {:ok, plugin} = Janus.PluginManager.add_stream(stream, state.participant_id)
    participant = %Janus.Participant{id: state.participant_id, publishing_plugin: plugin}
    state = Map.put(state, :stream_ids, [stream_id]) |> Map.put(:participant, participant)
    {:next_state, :start_publish, data, [{:reply, from, {state, Janus.ResponseCreator.create_response(command, command["id"], stream_id)}}]}
  end

  def handle_event({:call, from}, {:advance_stream, command, state, web_socket, []}, :start_publish, data) do
    {:next_state, :play, data, [{:reply, from, data}]}
  end

  def handle_event({:call, from}, {:advance_stream, command, state, web_socket, []}, :play, data) do
    {:next_state, :start_play, data, [{:reply, from, data}]}
  end

  def handle_event({:call, from}, {:advance_stream, command, state, web_socket, []}, :start_play, data) do
    {:keep_state_and_data, [{:reply, from, data}]}
  end

  defp via_tuple(id) do
    {:via, Registry, {:stream_state_guard_registry, id}}
  end

  def advance_stream(stream_id, command, state, web_socket, additional_args \\ []) do
    GenStateMachine.call(via_tuple(stream_id), {:advance_stream, command, state, web_socket, additional_args})
  end
end
