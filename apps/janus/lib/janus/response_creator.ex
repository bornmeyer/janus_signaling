defmodule Janus.ResponseCreator do
    
    def create_response(%{"command" => "publish"}, stream_id, args \\ []) do
        %{
            "command": "start",
            "streamId": stream_id
        }
    end

    def create_response(%{"command" => "takeConfiguration"}, stream_id, [sdp: sdp, type: type] = args) do
        %{
            "command": "takeConfiguration",
            "streamId": stream_id,
            "type": type,
            "sdp": sdp
        }
    end
end