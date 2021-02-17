defmodule Janus.EventRouter do
  require Logger

  def handle_event(%{"janus" => "webrtcup", "sender" => sender, "session_id" => _session_id}) do
    relevant_stream =
    DynamicSupervisor.which_children(Janus.StreamSupervisor)
    |> Enum.map(fn {_, x, _, _} -> Janus.StreamInfrastructureSupervisor.get_stream(x)  end)
    |> Enum.find(nil, fn x -> Janus.Stream.get_handle_id(x) == sender end)
    if Janus.Stream.publisher?(relevant_stream) do
      Task.start(fn -> Janus.Broadcast.broadcast_stream_started(Janus.Stream.get_participant_id(relevant_stream), relevant_stream) end)
    end
  end

  def handle_event(%{"videoroom" => "joined", "id" => id}) do
    Task.start(fn -> Janus.Broadcast.broadcast_join(id) end)
  end
end
