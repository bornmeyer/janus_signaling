defmodule Janus.CommandRouter do
    require Logger

    def route(:after_connect, %{:participant_id => participant_id, :room_id => room_id}, web_socket) do
        allready_connected_participants = Janus.StreamManager.get_all_participants_for_room(room_id, participant_id)
        response = %{
            :method => "participants",
            :params => %{
                :participants => allready_connected_participants
            }
        }
        General.SocketHandler.push(web_socket, response)
    end

    def route(%{"method" => "publish", "id" => request_id} = command, state, web_socket) do
        id = UUID.uuid4()
        {:ok, plugin} = Janus.PluginManager.new(state.participant_id, state.room_id)
        stream = Janus.StreamSupervisor.start_child(id, state.participant_id, state.room_id, web_socket, plugin.handle_id)
        Janus.StreamManager.add_stream(state.participant_id, stream)

        {:ok, plugin} = Janus.PluginManager.add_stream(state.participant_id, stream)
        participant = %Janus.Participant{id: state.participant_id, publishing_plugin: plugin}

        state = Map.put(state, :stream_ids, [id]) |> Map.put(:participant, participant)
        {state, Janus.ResponseCreator.create_response(command, request_id, id)}
    end

    def route(%{"method" => "startPublish", "params" => %{"sdp" => sdp, "streamId" => stream_id}, "id" => request_id} = command, state, _web_socket) do
        {:ok, sdp, type, room_id} = Janus.Stream.create_answer(stream_id, sdp)
        plugin = Janus.PluginManager.get_plugin(state.participant_id)
        plugin = %{plugin | room_id: room_id}
        Janus.PluginManager.update_plugin(state.participant_id, plugin)

        response = Janus.ResponseCreator.create_response(command, request_id, stream_id, sdp: sdp, type: type)
        {state, response}
    end

    def route(%{"method" => "startPlay", "params" => %{"sdp" => sdp, "streamId" => stream_id}, "id" => request_id} = command, state, _web_socket) do
        Janus.Stream.set_remote_description(stream_id, sdp, "answer", state.participant)

        web_socket = Janus.Stream.get_socket(stream_id)
        Task.start(fn -> General.SocketHandler.push(web_socket, Janus.Notifications.stream_started_notification(state.participant.id, stream_id)) end)

        {state, Janus.ResponseCreator.create_response(command, request_id, stream_id)}
    end

    def route(%{"method" => "addIceCandidate", "params" => %{"streamdId" => stream_id, "sdpMLineIndex" => sdp_m_line_index,
     "sdpMid" => sdp_mid, "candidate" => candidate}}, _state, _web_socket) do
        Janus.Stream.add_candidate(stream_id, sdp_m_line_index, sdp_mid, candidate)
    end

    def route(%{"method" => "play", "params" => %{"streamId" => stream_id}, "id" => request_id} = command, state, web_socket) do
        command |> inspect |> Logger.info
        id = UUID.uuid4()
        {:ok, plugin} = Janus.PluginManager.new(state.participant_id, state.room_id, :subscriber)
        participant = %{state.participant | subscribing_plugin: plugin }
        publishing_stream = Janus.Stream.get(stream_id)
        Janus.StreamSupervisor.start_child(id, participant.id, plugin.room_id, web_socket, plugin.handle_id, :subscriber, publishing_stream)
        |> Janus.StreamManager.add_stream(state.participant_id)
        |> Janus.PluginManager.add_stream(state.participant_id)
        state = Map.put(state, :stream_ids, [id | state.stream_ids]) |> Map.put(:participant, participant)
        {type, sdp} = Janus.Stream.create_offer(id, plugin)
        response = Janus.ResponseCreator.create_response(command, request_id, stream_id, sdp: sdp, type: type)
        {state, response}
    end

    def route(%{"method" => "stop"} = command, _state, _web_socket) do
        command |> inspect |> Logger.info
    end

    def route(%{"method" => "getParticipants"} = command, _state, _web_socket) do
        command |> inspect |> Logger.info
    end

    def route(command, _state, _web_socket) do
        command |> inspect |> Logger.info
    end

    @spec destroy(atom | %{:participant_id => any, optional(any) => any}) :: :ok
    def destroy(state) do
        participant_id = state.participant_id
        streams = Janus.StreamManager.get_streams_for(participant_id)
        for stream <- streams do
            Janus.Stream.destroy(stream)
        end
        Janus.StreamManager.remove_all_streams_for(participant_id)
        Janus.PluginManager.delete_plugins_for(participant_id)
    end
end
