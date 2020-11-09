defmodule Janus.Plugin do
  defstruct handle_id: nil, session_id: nil, participant_id: nil, room_id: nil, publishing_stream: nil, subscribing_streams: [], type: :publisher
end
