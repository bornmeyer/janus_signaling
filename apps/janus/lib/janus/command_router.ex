defmodule Janus.CommandRouter do
    require Logger

    defp route_internal(%{"method" => :after_connect}, %{:participant_id => participant_id, :room_id => room_id}, web_socket) do
        allready_connected_participants = Janus.StreamManager.get_all_participants_for_room(room_id, participant_id)
        response = %{
            :method => "participants",
            :params => %{
                :participants => allready_connected_participants
            }
        }
        response |> inspect |> Logger.info
        General.SocketHandler.push(web_socket, response)
    end

    defp route_internal(%{"method" => "publish"} = command, state, web_socket) do
        id = UUID.uuid4()
        {:ok, plugin} = Janus.PluginManager.new(state.participant_id, state.room_id)
        Janus.StreamSupervisor.start_child(id, state.participant_id, state.room_id, web_socket, plugin.handle_id)
        Janus.StreamStateGuard.advance_stream(id, command, state, web_socket, stream_id: id)
    end

    defp route_internal(%{"method" => "startPublish", "params" => %{"sdp" => sdp, "streamId" => stream_id}} = command, state, web_socket) do
        Janus.StreamStateGuard.advance_stream(stream_id, command, state, web_socket, sdp: sdp)
    end

    defp route_internal(%{"method" => "play", "params" => %{"streamId" => stream_id}} = command, state, web_socket) do
        id = UUID.uuid4()
        Janus.StreamStateGuard.advance_stream(stream_id, command, state, web_socket, stream_id: id)
    end

    defp route_internal(%{"method" => "startPlay", "params" => %{"sdp" => sdp, "streamId" => stream_id}} = command, state, web_socket) do
        Janus.StreamStateGuard.advance_stream(stream_id, command, state, web_socket, stream_id: stream_id, sdp: sdp)
    end

    defp route_internal(%{"method" => "addIceCandidate", "params" => %{"streamdId" => stream_id, "sdpMLineIndex" => sdp_m_line_index,
     "sdpMid" => sdp_mid, "candidate" => candidate}}, _state, _web_socket) do
        Janus.Stream.add_candidate(stream_id, sdp_m_line_index, sdp_mid, candidate)
    end

    defp route_internal(%{"method" => "stop"} = command, _state, _web_socket) do
        command |> inspect |> Logger.info
    end

    defp route_internal(%{"method" => "getParticipants"} = command, _state, _web_socket) do
        command |> inspect |> Logger.info
    end

    def route(command, state, web_socket) do
        Map.fetch(command, "method") |> inspect |> Logger.info
        route_internal(command, state, web_socket)
    end

    @spec destroy(atom | %{:participant_id => any, optional(any) => any}) :: :ok
    def destroy(state) do
        participant_id = state.participant_id
        streams = Janus.StreamManager.get_streams_for(participant_id)
        plugin = Janus.PluginManager.get_plugin(participant_id)
        for stream <- streams do
            "terminating #{stream |> inspect}(#{Janus.Stream.get_type(stream)})" |> Logger.info
            Janus.Stream.destroy(stream, plugin)
        end
        Janus.StreamManager.remove_all_streams_for(participant_id)
        Janus.PluginManager.delete_plugins_for(participant_id)
    end


end
