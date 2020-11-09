defmodule Janus.RoomManager do
    use GenServer
    require Logger

    def child_spec do
        %{
            id: __MODULE__,
            start: {__MODULE__, :start_link, []},
            type: :worker,
            restart: :transient,
            shutdown: 500
        }
    end

    def start_link do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init(_) do
        {:ok, []}
    end

    def handle_call({:create, room_id, %{"list" => existing_rooms}, handle_id}, _from, state) do
        room = case Enum.find(existing_rooms, fn x -> x["room"] == room_id end) do
            nil -> Janus.Dispatcher.send_message(Janus.Messages.create_room_message(room_id, handle_id))
            found -> found
        end
        {:reply, room["room"], state}
    end

    def handle_call({:list_rooms, handle_id}, _from, state) do
        rooms = Janus.Dispatcher.send_message(Janus.Messages.list_rooms_message(handle_id))
        {:reply, rooms, state}
    end

    def handle_call({:join, room_id, participant_id, handle_id}, _from, state) do
        result = Janus.Dispatcher.send_message(Janus.Messages.join_room_message(room_id, participant_id, handle_id))
        result |> inspect |> Logger.info
        Janus.EventRouter.handle_event(result)
        {:reply, result, state}
    end

    def create_room(room_id, existing_rooms, handle_id) do
        GenServer.call(__MODULE__, {:create, room_id, existing_rooms, handle_id})
    end

    def list_rooms(handle_id) do
        GenServer.call(__MODULE__, {:list_rooms, handle_id})
    end

    def join_room(room_id, participant_id, handle_id) do
        GenServer.call(__MODULE__, {:join, room_id, participant_id, handle_id})
    end


end
