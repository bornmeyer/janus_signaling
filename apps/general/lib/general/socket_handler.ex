defmodule General.SocketHandler do
    require Logger        
    @behaviour :cowboy_websocket

    def init(%{pid: pid, qs: query_params} = request, _state) do
        Logger.info("init")
        params = query_params |> URI.decode_query 
        Logger.info("params: #{params |> inspect}")
        participant_id = String.to_integer(params["participant_id"])
        room_id = String.to_integer(params["room_id"])
        state = %{registry_key: pid, room_id: room_id, participant_id: participant_id}
        {:cowboy_websocket, request, state}
    end

    def websocket_init(state) do
        Logger.info("websocket_init")
        Registry.General
        |> Registry.register(state.registry_key, {})
        {:ok, state}
    end

    def websocket_handle({:text, json}, state) do
        payload = Poison.decode!(json)
        {state, response} = payload |> General.CommandRouter.route(state)
        {:reply, {:text, response |> Poison.encode!}, state}
    end

    def websocket_handle(request, state) do
        request |> inspect |> Logger.info
        {:reply, request, state}
    end
    
    def websocket_info(message, state) do
        Logger.info("pushing #{message |> inspect}")
       {:reply, {:text, message}, state} 
    end

   
    def terminate(reason, _req, state) do
        reason |> inspect |> Logger.info
        General.Stream.destroy(state.stream_id)
        :ok
    end
    
    def push(websocket, message) do
        send(websocket, message)     
        
    end
end