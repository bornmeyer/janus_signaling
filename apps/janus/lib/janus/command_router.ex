defmodule Janus.CommandRouter do
    require Logger

    def route(%{"command" => "publish"} = command, state, web_socket) do
        id = UUID.uuid4()
        {:ok, plugin} = Janus.PluginManager.new(state.participant_id, state.room_id)
        stream = Janus.StreamSupervisor.start_child(id, state.participant_id, state.room_id, web_socket, plugin.handle_id, :publisher)
        Janus.StreamManager.add_stream(state.participant_id, stream)

        {:ok, plugin} = Janus.PluginManager.add_stream(state.participant_id, stream)
        participant = %Janus.Participant{id: state.participant_id, publishing_plugin: plugin}

        state = Map.put(state, :stream_ids, [id]) |> Map.put(:participant, participant)
        participant_ids = Janus.StreamManager.get_all_participants_for_room(state.room_id, state.participant_id)
        if length(participant_ids) > 0 do
            General.SocketHandler.push(web_socket, %{command: "participants", participants: participant_ids})
        end

        {state, Janus.ResponseCreator.create_response(command, id)}
    end

    def route(%{"command" => "takeConfiguration", "sdp" => sdp, "streamId" => stream_id, "type" => "offer"} = command, state, web_socket) do
        "takeConfiguration: offer" |> Logger.info
        {:ok, sdp, type, room_id} = Janus.Stream.create_answer(stream_id, sdp)
        plugin = Janus.PluginManager.get_plugin(state.participant_id)
        plugin = %{plugin | room_id: room_id}
        Janus.PluginManager.update_plugin(state.participant_id, plugin)

        response = Janus.ResponseCreator.create_response(command, stream_id, sdp: sdp, type: type)
        {state, response}
    end

    def route(%{"command" => "takeConfiguration", "sdp" => sdp, "streamId" => stream_id, "type" => "answer"} = command, state, web_socket) do
        state |> inspect |> Logger.info
        Janus.Stream.set_remote_description(stream_id, sdp, "answer", state.participant)
        {state, Janus.Notifications.play_started(state.participant.id)}
    end

    def route(%{"command" => "takeCandidate"} = command, state, web_socket) do
        command |> inspect |> Logger.info
    end

    def route(%{"command" => "play", "streamId" => stream_id} = command, state, web_socket) do
        id = UUID.uuid4()
        {:ok, plugin} = Janus.PluginManager.new(state.participant_id, state.room_id)
        participant = %{state.participant | subscribing_plugin: plugin }

        stream = Janus.StreamSupervisor.start_child(id, participant.id, plugin.room_id, web_socket, plugin.handle_id, :subscriber)
        Janus.StreamManager.add_stream(state.participant_id, stream)
        state = Map.put(state, :stream_ids, [id | state.stream_ids]) |> Map.put(:participant, participant)
        {type, sdp} = Janus.Stream.create_offer(id, plugin)
        {state, Janus.ResponseCreator.create_response(command, stream_id, sdp: sdp, type: type)}
    end

    def route(%{"command" => "stop"} = command, state, web_socket) do
        command |> inspect |> Logger.info
    end

    def route(%{"command" => "getParticipants"} = command, state, web_socket) do
        command |> inspect |> Logger.info
    end

    def route(command, state, web_socket) do
        command |> inspect |> Logger.info
    end

    def destroy(state) do
        participant_id = state.participant_id
        streams = Janus.StreamManager.get_streams_for(participant_id)
        for stream <- streams do
            Janus.Stream.destroy(stream)
        end
        Janus.StreamManager.remove_all_streams_for(participant_id)
    end
end
