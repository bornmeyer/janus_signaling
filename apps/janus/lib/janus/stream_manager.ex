defmodule Janus.StreamManager do
    use Agent
    require Logger

    def start_link(_) do
        Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def add_stream(participant_id, stream) do
        streams = Agent.get(__MODULE__, fn map -> map |> Map.fetch(participant_id) end)
        {:ok, list} = case streams do
            :error -> {:ok, []}
            contents -> contents
        end
        Agent.update(__MODULE__, fn map -> Map.put(map, participant_id, [stream | list]) end)
    end

    def get_streams_for(participant_id) do
        {:ok, result} = Agent.get(__MODULE__, fn map -> Map.fetch(map, participant_id) end)
        result
    end

    def remove_all_streams_for(participant_id) do
        "removing streams for #{participant_id}" |> Logger.info
        Agent.update(__MODULE__, fn map -> map |> Map.delete(participant_id) end)
    end

    def get_all_participants_for_room(room_id, participant_id) do
        streams = Agent.get(__MODULE__, fn map -> map |> Map.values end) |> List.flatten
        streams
        |> Enum.filter(fn x -> Janus.Stream.publisher?(x) end)
        |> Enum.filter(fn x -> Janus.Stream.get_room_id(x) == room_id end)
        |> Enum.map(fn x -> Janus.Stream.get_participant_id(x) end)
        |> Enum.filter(fn x -> x != participant_id end)
        |> Enum.map(fn x -> %{"participantId": x, streams: x |> Janus.StreamManager.get_streams_for |> Enum.map(fn y -> Janus.Stream.get_stream_id(y) end)} end)
    end

    def broadcast_join(participant_id) do
        streams =
            Janus.StreamManager.get_streams_for(participant_id)
            |> Enum.filter(fn x -> Janus.Stream.publisher?(x) end)
            |> Enum.map(fn x -> Janus.Stream.get_stream_id(x) end)
        message = Janus.Notifications.joined_room_notification(participant_id, streams)

        all_streams = Agent.get(__MODULE__, fn map -> map |> Map.values end) |> List.flatten
        broadcast(message, all_streams, fn x -> Janus.Stream.get_participant_id(x) != participant_id end)
    end

    def broadcast_stream_started(participant_id, stream) do
        streams = [Janus.Stream.get_stream_id(stream)]
        message = Janus.Notifications.stream_started_notification(participant_id, streams)
        "broadcasting message: #{message |> inspect}" |> Logger.info
        all_streams = Agent.get(__MODULE__, fn map -> map |> Map.values end) |> List.flatten
        broadcast(message, all_streams, fn x -> Janus.Stream.get_participant_id(x) != participant_id && Janus.Stream.publisher?(x) end)
    end

    defp broadcast(message, streams, streams_filter) do
        sockets =
            streams
            |> Enum.filter(streams_filter)
            |> Enum.map(fn x -> Janus.Stream.get_socket(x) end)
        for socket <- sockets do
            General.SocketHandler.push(socket, message)
        end
    end
end
