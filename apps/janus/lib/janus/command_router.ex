defmodule Janus.CommandRouter do
    require Logger 

    def route(%{"command" => "publish"} = command, state) do
        id = UUID.uuid4() 
        stream = Janus.StreamSupervisor.start_child(id, state.participant_id, state.room_id)
        Janus.StreamManager.add_stream(state.participant_id, stream)
        state = Map.put(state, :stream_id, id)
        {state, Janus.ResponseCreator.create_response(command, id)}
    end

    def route(%{"command" => "takeConfiguration", "sdp" => sdp, "streamId" => stream_id, "type" => "offer"} = command, state) do
        {:ok, sdp, type} = Janus.Stream.create_answer(stream_id, sdp)
        response = Janus.ResponseCreator.create_response(command, stream_id, sdp: sdp, type: type)
        {state, response}
    end

    def route(%{"command" => "takeCandidate"} = command, state) do
        command |> inspect |> Logger.info
    end

    def route(%{"command" => "play"} = command, state) do
        command |> inspect |> Logger.info
    end

    def route(%{"command" => "stop"} = command, state) do
        command |> inspect |> Logger.info
    end

    def route(%{"command" => "getParticipants"} = command, state) do
        command |> inspect |> Logger.info
    end

    def destroy(state) do
        participant_id = state.participant_id
        {:ok, streams} = Janus.StreamManager.get_streams_for(participant_id)
        streams |> inspect |> Logger.info
        for stream <- streams do
            Janus.Stream.destroy(stream)
        end
        Janus.StreamManager.remove_all_streams_for(participant_id)
    end
end