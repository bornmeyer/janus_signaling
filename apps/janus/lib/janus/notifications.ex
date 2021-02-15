defmodule Janus.Notifications do

  def joined_room_notification(participant_id, streams) do
    %{
      command: "notification",
      type: "joinedRoom",
      streams: streams,
      participantId: participant_id
    }
  end

  def stream_started_notification(participant_id, stream) do
    %{
      method: "startedPublishing",
      params: %{
          streamId: stream,
          participantId: participant_id
      }
    }
  end

  def play_started(participant_id, stream_id) do
    %{
        method: "notification",
        params: %{
          participantId: participant_id,
          streamId: stream_id
        }
    }
  end
end
