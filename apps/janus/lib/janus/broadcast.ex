defmodule Janus.Broadcast do
  require Logger

    def broadcast_join(participant_id) do
        streams =
            Janus.StreamManager.get_streams_for(participant_id)
            |> Enum.filter(fn x -> Janus.Stream.publisher?(x) end)
            |> Enum.map(fn x -> Janus.Stream.get_stream_id(x) end)
        message = Janus.Notifications.joined_room_notification(participant_id, streams)

        all_streams = Agent.get(Janus.StreamManager, fn map -> map |> Map.values end) |> List.flatten
        broadcast(message, all_streams, fn x -> Janus.Stream.get_participant_id(x) != participant_id end)
    end

    def broadcast_stream_started(participant_id, stream) do
        streams = Janus.Stream.get_stream_id(stream)
        message = Janus.Notifications.stream_started_notification(participant_id, streams)
        "broadcasting message: #{message |> inspect}" |> Logger.info
        all_streams = Agent.get(Janus.StreamManager, fn map -> map |> Map.values end) |> List.flatten
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
