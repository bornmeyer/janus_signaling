defmodule General.CommandRouter do
    require Logger 

    def route(%{"command" => "publish"} = command, state) do
        id = UUID.uuid4() 
        stream = General.StreamSupervisor.start_child(id, state.participant_id, state.room_id)
        state = Map.put(state, :stream_id, id)
        {state, General.ResponseCreator.create_response(command, id)}
    end

    def route(%{"command" => "takeConfiguration", "sdp" => sdp, "streamId" => stream_id, "type" => "offer"} = command, state) do
        {:ok, sdp, type} = General.Stream.create_answer(stream_id, sdp)
        response = General.ResponseCreator.create_response(command, stream_id, sdp: sdp, type: type)
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
end