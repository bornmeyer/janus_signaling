defmodule Janus.ResponseCreator do

    def create_response(%{"method" => "publish"}, request_id, stream_id, _args \\ []) do
        %{
            "id": request_id,
            "result": %{
                "streamId": stream_id
            }
        }
    end

    def create_response(%{"method" => "startPublish"}, request_id, stream_id, [sdp: sdp, type: type]) do
        %{
            "id": request_id,
            "result": %{
                "sdp": sdp
            }
        }
    end

    def create_response(%{"method" => "play"}, request_id, stream_id, [sdp: sdp, type: type]) do
        %{
            id: request_id,
            result: %{
                sdp: sdp
            }
        }
    end

    def create_response(%{"method" => "startPlay"}, request_id, stream_id ,_args) do
        %{
            id: request_id,
            result: %{}
        }
    end

    def create_response(%{"method" => "takeConfiguration"}, request_id, stream_id, [sdp: sdp, type: type]) do
        %{
            "method": "takeConfiguration",
            "streamId": stream_id,
            "type": type,
            "sdp": sdp
        }
    end
end
