defmodule Janus.StreamManager do
    use Agent
    require Logger

    def start_link(_) do
        Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def add_stream(stream, participant_id) do
        streams = Agent.get(__MODULE__, fn map -> map |> Map.fetch(participant_id) end)
        {:ok, list} = case streams do
            :error -> {:ok, []}
            contents -> contents
        end
        Agent.update(__MODULE__, fn map -> Map.put(map, participant_id, [stream | list]) end)
        stream
    end

    def get_streams_for(participant_id) do
        {:ok, result} = Agent.get(__MODULE__, fn map -> Map.fetch(map, participant_id) end)
        result
    end

    def get_all_streams() do
        {:ok, result} = Agent.get(__MODULE__, fn map -> Map.values(map) end)
        result |> inspect |> Logger.info
        result |> List.flatten
    end

    def remove_all_streams_for(participant_id) do
        "removing streams for #{participant_id}" |> Logger.info
        Agent.update(__MODULE__, fn map -> map |> Map.delete(participant_id) end)
    end

    def get_all_participants_for_room(room_id, participant_id) do
        streams = Agent.get(__MODULE__, fn map -> map |> Map.values end) |> List.flatten
        streams
        |> Enum.filter(fn x -> Janus.Stream.get_participant_id(x) != participant_id end)
        |> Enum.filter(fn x -> Janus.Stream.publisher?(x) end)
        |> Enum.filter(fn x -> Janus.Stream.get_room_id(x) == room_id end)
        |> Enum.map(fn x -> Janus.Stream.get_participant_id(x) end)
        |> Enum.map(fn x -> %{participantId: x, streams: x |> Janus.StreamManager.get_streams_for |> Enum.map(fn y -> Janus.Stream.get_stream_id(y) end)} end)
    end
end
