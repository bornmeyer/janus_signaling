defmodule Janus.StreamManager do
    use Agent  
    require Logger

    def start_link(_) do
        Agent.start_link(fn -> %{} end, name: __MODULE__)
    end
    
    def add_stream(participant_id, stream) do
        streams = Agent.get(__MODULE__, fn map -> map |> Map.fetch(participant_id) end)
        streams |> inspect |> Logger.info
        {:ok, list} = case streams do
            :error -> {:ok, []}
            contents -> case contents |> Map.has_key?(participant_id) do
                true -> contents |> Map.fetch(participant_id)
                false -> {:ok, []}
            end    
        end
        Agent.update(__MODULE__, fn map -> Map.put(map, participant_id, [stream | list]) end)
    end

    def get_streams_for(participant_id) do
        participant_id |> Logger.info
        
        result = Agent.get(__MODULE__, fn map -> Map.fetch(map, participant_id) end)
        result |> inspect |> Logger.info
        result
    end

    def remove_all_streams_for(participant_id) do
        "removing streams for #{participant_id}" |> Logger.info
        Agent.update(__MODULE__, fn map -> map |> Map.delete(participant_id) end)
    end
end