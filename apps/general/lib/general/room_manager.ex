defmodule General.RoomManager do
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

    def handle_call({:create, room_id, %{"list" => existing_rooms}} = list, _from, state) do       
        Enum.find(existing_rooms, fn x -> x["room"] == room_id end) |> inspect |> Logger.info 
        room = case Enum.find(existing_rooms, fn x -> x["room"] == room_id end) do
            nil -> General.Dispatcher.send_message(General.Messages.create_room_message(room_id))
            found -> found
        end
        Logger.info("ROOM #{room |> inspect}")
        {:reply, room["room"], state}
    end

    def handle_call({:list_rooms}, _from, state) do
        rooms = General.Dispatcher.send_message(General.Messages.list_rooms_message)
        {:reply, rooms, state}
    end

    def handle_call({:join, room_id, participant_id}, _from, state) do
        result = General.Dispatcher.send_message(General.Messages.join_room_message(room_id, participant_id))
        {:reply, result, state}
    end

    def create_room(room_id, existing_rooms) do
        GenServer.call(__MODULE__, {:create, room_id, existing_rooms})
    end

    def list_rooms do
        GenServer.call(__MODULE__, {:list_rooms})
    end

    def join_room(room_id, participant_id) do
        GenServer.call(__MODULE__, {:join, room_id, participant_id})
    end

    
end