defmodule Janus.EventRouter do
  require Logger

  def handle_event(%{"janus" => "webrtcup", "sender" => sender, "session_id" => _session_id}) do
    {_, relevant_stream, _, _} =
      DynamicSupervisor.which_children(Janus.StreamSupervisor)
      |> Enum.find(nil, fn {_, x, _, _} -> Janus.Stream.get_handle_id(x) == sender end)
    if Janus.Stream.publisher?(relevant_stream) do
      Janus.StreamManager.broadcast_stream_started(Janus.Stream.get_participant_id(relevant_stream), relevant_stream)
    end
  end

  def handle_event(%{"janus" => "event", "plugindata" => %{"plugin" => "janus.videoroom.plugin", "data" => data}}) do
    Janus.StreamManager.broadcast_join(data.id)
  end
end
