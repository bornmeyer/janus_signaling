defmodule Janus.Stream do
    use GenServer
    require Logger

    def child_spec(id, participant_id, room_id) do
        %{
            id: id,
            start: {__MODULE__, :start_link, [%{id: id, participant_id: participant_id, room_id: room_id}]},
            type: :worker,
            restart: :transient,
            shutdown: 500
        }
    end

    def start_link(state) do
        GenServer.start_link(__MODULE__, state, name: via_tuple(state.id))
    end

    def init(state) do
        {:ok, state}
    end

    def handle_call(:get_id, _from, state) do
        
        {:reply, state[:id], state}
    end

    def handle_call({:create_answer, id, sdp}, _from, state) do
        websocket = state[:websocket]
        existing_rooms = Janus.RoomManager.list_rooms
        room_id = Janus.RoomManager.create_room(state.room_id, existing_rooms)
        Janus.RoomManager.join_room(room_id, state[:participant_id])

        publish_result = Janus.Dispatcher.send_message(Janus.Messages.publish_message(sdp))
        {:reply, {:ok, publish_result.jsep["sdp"], publish_result.jsep["type"]}, state}
    end

    def handle_info(:destroy, state) do
        Logger.info("destroying stream #{state.id} for participant #{state.participant_id}")
        {:stop, :normal, state}
    end

    def handle_call(:get_participant_id, _from, state) do
        {:reply, state.participant_id, state}
    end

    defp via_tuple(id) do
        {:via, Registry, {:stream_registry, id}}
    end

    def get_id(stream) do
        Logger.info("getting id")
        GenServer.call(stream, :get_id)
    end

    def get_participant_id(stream) do
        GenServer.call(stream, :get_participant_id)
    end

    def create_answer(id, sdp) do
        GenServer.call(via_tuple(id), {:create_answer, id, sdp})
    end

    def destroy(stream) do
        send(stream, :destroy)
    end
end