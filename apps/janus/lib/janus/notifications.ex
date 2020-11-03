defmodule Janus.Notifications do

  def joined_room_notification(participant_id, streams) do
    %{
      command: "notification",
      type: "joinedRoom",
      streams: streams,
      "participantId": participant_id
    }
  end

  def stream_started_notification(participant_id, streams) do
    %{
      command: "notification",
      type: "streamStarted",
      streams: streams,
      "participantId": participant_id
    }
  end

  def play_started(participant_id) do
    %{
        command: "notification",
        type: "playStarted",
        "participantId": participant_id
    }
  end
end
