defmodule Janus.StreamSupervisor do
    use DynamicSupervisor
    require Logger

    def start_link(_args) do
        DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init(_args) do
        DynamicSupervisor.init(strategy: :one_for_one)
    end

    def start_child(stream_id, participant_id, room_id, web_socket, handle_id, type \\ :publisher, subscribed_to \\ nil) do
        args = %{
            id: stream_id,
            participant_id: participant_id,
            room_id: room_id,
            web_socket: web_socket,
            handle_id: handle_id,
            type: type,
            subscribed_to: subscribed_to
        }
        child_spec = Janus.StreamInfrastructureSupervisor.child_spec(args)
        {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
        pid
    end

    def get_all_streams do
        DynamicSupervisor.which_children(__MODULE__)
        |> Enum.map(fn {_, x, _, _} -> Janus.StreamInfrastructureSupervisor.get_stream(x) end)
    end

    def get_all_stream_guards do
        DynamicSupervisor.which_children(__MODULE__)
        |> Enum.map(fn {_, x, _, _} -> Janus.StreamInfrastructureSupervisor.get_stream_guard(x) end)
    end
end
