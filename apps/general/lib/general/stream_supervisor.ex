defmodule General.StreamSupervisor do
    use DynamicSupervisor
    alias General.Stream
    require Logger

    def start_link(_args) do
        DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init(_args) do
        DynamicSupervisor.init(strategy: :one_for_one)
    end

    def start_child(stream_id, participant_id, room_id) do
        child_spec = General.Stream.child_spec(stream_id, participant_id, room_id)
        {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
        pid
    end
end