defmodule Janus.Stream do
    use GenServer
    require Logger

    def child_spec(id, participant_id, room_id, web_socket, handle_id, type \\ :publisher, subscribed_to \\ nil) do
        %{
            id: id,
            start: {__MODULE__, :start_link, [%{stream_id: id,
            participant_id: participant_id,
            room_id: room_id,
            web_socket: web_socket,
            handle_id: handle_id,
            playing_streams: %{},
            subscribed_to: subscribed_to,
            type: type}]},
            type: :worker,
            restart: :transient,
            shutdown: 500
        }
    end

    def start_link(state) do
        GenServer.start_link(__MODULE__, state, name: via_tuple(state.stream_id))
    end

    def init(state) do
        "stream##{state.stream_id} started for #{state.participant_id} as #{state.type} in #{state.room_id}" |> Logger.info
        "subscribed_to #{state.subscribed_to |> inspect }" |> Logger.info
        {:ok, state}
    end

    def handle_call({:create_answer, _id, sdp}, _from, state) do
        handle_id = state.handle_id
        existing_rooms = Janus.RoomManager.list_rooms(handle_id)


        room_id = room_manager().create_room(state.room_id, existing_rooms, handle_id)

        room_manager().join_room(room_id, state.participant_id, handle_id)
        publish_message = Janus.Messages.publish_message(handle_id, sdp)
        publish_result = dispatcher().send_message(publish_message)
        {:reply, {:ok, publish_result.jsep["sdp"], publish_result.jsep["type"], room_id}, state}
    end

    def handle_call({:create_offer, plugin}, _from, state) do
        message = Janus.Messages.join_message(plugin.room_id, plugin.participant_id, plugin.handle_id)
        %{jsep: jsep} = dispatcher().send_message(message)
        {:reply, {jsep["type"], jsep["sdp"]}, state}
    end

    def handle_call({:set_remote_description, sdp, sdp_type, participant}, _from, state) do
        "sending start for #{participant.subscribing_plugin.handle_id}/#{state.stream_id} -> #{participant.id}" |> Logger.info
        dispatcher().send_message(Janus.Messages.start_message(sdp, sdp_type, participant.subscribing_plugin.handle_id))
        "start for #{state.handle_id}/#{state.stream_id} -> #{state.participant_id} sent" |> Logger.info
        {:reply, :ok, state}
    end

    def handle_call(:get_data, _from, state) do
        {:reply, state, state}
    end

    def handle_call(:get_self, _from, state) do
        {:reply, self(), state}
    end

    def handle_call({:get_data_via_key, key}, _from, state) do
        {:reply, state |> Map.fetch!(key), state}
    end

    def handle_call({:is, key}, _from, state) do
        {:reply, state.type == key, state}
    end

    def handle_call({:add_playing_handle, play_id, handle_id}, _from, state) do
        play_streams = state.playing_streams |> Map.put(play_id, handle_id)
        state = state |> Map.put(:playing_streams, play_streams)
        {:reply, :ok, state}
    end

    def handle_call({:get_playing_handle, play_id}, _from, state) do
        {:reply, {:ok, state.playing_streams |> Map.get(play_id)}, state}
    end

    def handle_call({:add_candidate, sdp_mline_index, sdp_mid, candidate}, _from, state) do
        dispatcher().send_message(Janus.Messages.trickle_message(sdp_mid, sdp_mline_index, candidate))
        {:reply, :ok, state}
    end

    def handle_call(:get_publishing_stream, _from, state) do
        {:reply, state[:subscribed_to], state}
    end

    def handle_call(:leave, _from, state) do
        dispatcher().send_message(Janus.Messages.leave_message(state.handle_id))
        {:reply, :ok, state}
    end

    def handle_info({:destroy, plugin}, state) do
        dispatcher().send_message(Janus.Messages.leave_message(state.handle_id))
        Logger.info("destroying stream #{state.stream_id} for participant #{state.participant_id}")
        state.playing_streams |> inspect |> Logger.info
        case state.type do
            :publisher -> further_cleanup(plugin, state)
            :subscriber -> nil
        end
        {:stop, :client_disconnect, state}
    end

    defp further_cleanup(plugin, state) do
        #Janus.Messages.unpublish_message(state.handle_id) |> inspect |> Logger.info
        #dispatcher().send_message(Janus.Messages.unpublish_message(state.handle_id))
        plugin |> inspect |> Logger.info
    end

    defp via_tuple(id) do
        {:via, Registry, {:stream_registry, id}}
    end

    def create_answer(id, sdp) do
        GenServer.call(via_tuple(id), {:create_answer, id, sdp})
    end

    def create_offer(publishing_stream_id, plugin) do
        GenServer.call(via_tuple(publishing_stream_id), {:create_offer, plugin})
    end

    def destroy(stream, plugin) do
        send(stream, {:destroy, plugin})
    end

    def get_data(id) do
        GenServer.call(via_tuple(id), :get_data)
    end

    def get(id) do
        GenServer.call(via_tuple(id), :get_self)
    end

    def get_publishing_stream(stream) when is_pid(stream) do
        GenServer.call(stream, :get_publishing_stream)
    end

    def get_publishing_stream(id) do
        GenServer.call(via_tuple(id), :get_publishing_stream)
    end

    def get_room_id(stream) do
        GenServer.call(stream, {:get_data_via_key, :room_id})
    end

    def get_stream_id(stream) do
        GenServer.call(stream, {:get_data_via_key, :stream_id})
    end

    def get_participant_id(stream) when is_pid(stream) do
        GenServer.call(stream, {:get_data_via_key, :participant_id})
    end

    def get_participant_id(stream_id) do
        GenServer.call(via_tuple(stream_id), {:get_data_via_key, :participant_id})
    end

    def get_socket(stream) when is_pid(stream) do
        GenServer.call(stream, {:get_data_via_key, :web_socket})
    end

    def get_socket(id) do
       GenServer.call(via_tuple(id), {:get_data_via_key, :web_socket})
    end

    def get_type(stream) do
        GenServer.call(stream, {:get_data_via_key, :type})
    end

    def get_handle_id(stream) when is_pid(stream) do
        GenServer.call(stream, {:get_data_via_key, :handle_id})
    end

    def get_handle_id(stream_id) do
        GenServer.call(via_tuple(stream_id), {:get_data_via_key, :handle_id})
    end

    def set_remote_description(id, sdp, sdp_type, participant) do
        GenServer.call(via_tuple(id), {:set_remote_description, sdp, sdp_type, participant})
    end

    def add_handle_playing_handle(stream_id, playing_stream_id, handle_id) do
        GenServer.call(via_tuple(stream_id), {:add_playing_handle, playing_stream_id, handle_id})
    end

    def get_handle_for_playing_id(stream_id, playing_stream) do
        GenServer.call(via_tuple(stream_id), {:get_playing_handle, playing_stream})
    end

    def subscriber?(stream) when is_pid(stream) do
        GenServer.call(stream, {:is, :subscriber})
    end

    def publisher?(stream) when is_pid(stream) do
        GenServer.call(stream, {:is, :publisher})
    end

    def add_candidate(id, sdp_mline_index, sdp_mid, candidate) do
        GenServer.call(via_tuple(id), {:add_candidate, sdp_mline_index, sdp_mid, candidate})
    end

    def leave(stream) when is_pid(stream) do
        GenServer.call(stream, :leave)
    end

    def leave(stream_id) do
        GenServer.call(via_tuple(stream_id), :leave)
    end

    defp dispatcher do
        Application.fetch_env!(:janus, :dispatcher)
    end

    defp room_manager do
        Application.fetch_env!(:janus, :room_manager)
    end
end
