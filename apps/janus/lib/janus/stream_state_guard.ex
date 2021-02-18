defmodule Janus.StreamStateGuard do
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]
  require Logger

  def child_spec(stream_id) do
    %{
      id: "#{stream_id}_guard",
      start: {__MODULE__, :start_link, [%{stream_id: stream_id, last_state: nil}]},
      type: :worker,
      restart: :transient
    }
  end

  def start_link(state) do
    GenStateMachine.start_link(__MODULE__, {:publish, state}, name: via_tuple(state.stream_id))
  end

  def handle_event(:enter, event, state, data) do
    "Transitioning from #{data[:last_state] |> inspect} to #{event |> inspect}" |> Logger.info
    {:next_state, state, data |> Map.put(:last_state, event)}
  end

  def handle_event({:call, from}, {:advance_stream, command, state, _web_socket, [stream_id: stream_id]}, :publish, data) do
    stream = Janus.Stream.get(stream_id)
    Janus.StreamManager.add_stream(stream, state.participant_id)

    {:ok, plugin} = Janus.PluginManager.add_stream(stream, state.participant_id)
    participant = %Janus.Participant{id: state.participant_id, publishing_plugin: plugin}
    state = Map.put(state, :stream_ids, [stream_id]) |> Map.put(:participant, participant)
    {:next_state, :start_publish, data, [{:reply, from, {state, Janus.ResponseCreator.create_response(command, command["id"], stream_id)}}]}
  end

  def handle_event({:call, from}, {:advance_stream, command, state, _web_socket, [sdp: sdp]}, :start_publish, data) do
    "1" |> Logger.info
    {:ok, sdp, _type, room_id} = Janus.Stream.create_answer(data[:stream_id], sdp)
    "2" |> Logger.info
    plugin = Janus.PluginManager.get_plugin(state.participant_id)
    "3" |> Logger.info
    plugin = %{plugin | room_id: room_id}
    "4" |> Logger.info
    Janus.PluginManager.update_plugin(state.participant_id, plugin)
    "5" |> Logger.info
    response = Janus.ResponseCreator.create_response(command, command["id"], data[:stream_id], sdp: sdp)
    "6" |> Logger.info
    {:next_state, :play, data, [{:reply, from, {state, response}}]}
  end

  def handle_event({:call, from}, {:advance_stream, command, state, web_socket, [stream_id: subscriber_stream_id]}, :play, data) do
    {:ok, plugin} = Janus.PluginManager.new(state.participant_id, state.room_id, :subscriber)
    participant = %{state.participant | subscribing_plugin: plugin }
    publishing_stream = Janus.Stream.get(data[:stream_id])
    Janus.StreamSupervisor.start_child(subscriber_stream_id, participant.id, plugin.room_id, web_socket, plugin.handle_id, :subscriber, publishing_stream)
    stream = Janus.Stream.get(subscriber_stream_id)
    stream |> Janus.StreamManager.add_stream(state.participant_id)
    stream |> Janus.PluginManager.add_stream(state.participant_id)
    state = Map.put(state, :stream_ids, [subscriber_stream_id | state.stream_ids]) |> Map.put(:participant, participant)
    {_, sdp} = Janus.Stream.create_offer(subscriber_stream_id, plugin)
    response = Janus.ResponseCreator.create_response(command, command["id"], data[:stream_id], sdp: sdp)
    {:next_state, :start_play, data, [{:reply, from, {state, response}}]}
  end

  def handle_event({:call, from}, {:advance_stream, command, state, _web_socket, [stream_id: stream_id, sdp: sdp]}, :start_play, _data) do
    Janus.Stream.set_remote_description(stream_id, sdp, "answer", state.participant)

    stream = Janus.Stream.get(stream_id)
    Task.start(fn -> Janus.Broadcast.broadcast_stream_started(state.participant.id, stream) end)
    #Task.start(fn -> General.SocketHandler.push(web_socket, Janus.Notifications.stream_started_notification(state.participant.id, stream_id)) end)
    {:keep_state_and_data, [{:reply, from, {state, Janus.ResponseCreator.create_response(command, command["id"], stream_id)}}]}
  end


  defp via_tuple(id) do
    {:via, Registry, {:stream_state_guard_registry, "#{id}_guard"}}
  end

  def advance_stream(stream_id, command, state, web_socket, additional_args \\ []) do
    GenStateMachine.call(via_tuple(stream_id), {:advance_stream, command, state, web_socket, additional_args})
  end

end
