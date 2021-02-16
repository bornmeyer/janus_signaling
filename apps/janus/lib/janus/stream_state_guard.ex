defmodule Janus.StreamStateGuard do
  use GenStateMachine
  require Logger

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

  def handle_event({:call, from}, {:advance_stream, command, state, _web_socket, [sdp: sdp]}, :start_publish, data) do
    data |> inspect |> Logger.info
    {:ok, sdp, _type, room_id} = Janus.Stream.create_answer(data[:stream_id], sdp)
    plugin = Janus.PluginManager.get_plugin(state.participant_id)
    plugin = %{plugin | room_id: room_id}
    Janus.PluginManager.update_plugin(state.participant_id, plugin)

    response = Janus.ResponseCreator.create_response(command, command["id"], data[:stream_id], sdp: sdp)

    {:next_state, :play, data, [{:reply, from, {state, response}}]}
  end

  def handle_event({:call, from}, {:advance_stream, command, state, web_socket, [stream_id: subscriber_stream_id]}, :play, data) do
    {:ok, plugin} = Janus.PluginManager.new(state.participant_id, state.room_id, :subscriber)
    participant = %{state.participant | subscribing_plugin: plugin }
    publishing_stream = Janus.Stream.get(data[:stream_id])
    Janus.StreamSupervisor.start_child(subscriber_stream_id, participant.id, plugin.room_id, web_socket, plugin.handle_id, :subscriber, publishing_stream)
    |> Janus.StreamManager.add_stream(state.participant_id)
    |> Janus.PluginManager.add_stream(state.participant_id)
    state = Map.put(state, :stream_ids, [subscriber_stream_id | state.stream_ids]) |> Map.put(:participant, participant)
    {_, sdp} = Janus.Stream.create_offer(subscriber_stream_id, plugin)
    response = Janus.ResponseCreator.create_response(command, command["id"], data[:stream_id], sdp: sdp)
    {:next_state, :start_play, data, [{:reply, from, {state, response}}]}
  end

  def handle_event({:call, from}, {:advance_stream, command, state, web_socket, [stream_id: stream_id, sdp: sdp]}, :start_play, data) do
    Janus.Stream.set_remote_description(stream_id, sdp, "answer", state.participant)

    web_socket = Janus.Stream.get_socket(stream_id)
    Task.start(fn -> General.SocketHandler.push(web_socket, Janus.Notifications.stream_started_notification(state.participant.id, stream_id)) end)
    {:keep_state_and_data, [{:reply, from, {state, Janus.ResponseCreator.create_response(command, command["id"], stream_id)}}]}
  end

  defp via_tuple(id) do
    {:via, Registry, {:stream_state_guard_registry, id}}
  end

  def advance_stream(stream_id, command, state, web_socket, additional_args \\ []) do
    GenStateMachine.call(via_tuple(stream_id), {:advance_stream, command, state, web_socket, additional_args})
  end
end
