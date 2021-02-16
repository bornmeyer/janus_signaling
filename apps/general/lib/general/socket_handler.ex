defmodule General.SocketHandler do
    require Logger
    @behaviour :cowboy_websocket

    def init(%{pid: pid, qs: query_params} = request, _state) do
        Logger.info("init")
        params = query_params |> URI.decode_query
        Logger.info("params: #{params |> inspect}")
        participant_id = params["participant_id"]
        room_id = params["room_id"]
        state = %{registry_key: pid, room_id: room_id, participant_id: participant_id, backend: %CallProtocol.Janus{}}
        {:cowboy_websocket, request, state}
    end

    def websocket_init(state) do
        Logger.info("websocket_init")
        Registry.General
        |> Registry.register(state.registry_key, {})

        protocol = CallProtocol.get_module(%CallProtocol.Janus{})
        protocol.route(%{"method" => :after_connect}, state, self())
        {:ok, state}
    end

    def websocket_handle({:text, json}, state) do
        payload = Poison.decode!(json)
        protocol = CallProtocol.get_module(%CallProtocol.Janus{command: payload, state: state})
        {state, response} = payload |> protocol.route(state, self())
        {:reply, {:text, response |> Poison.encode!}, state}
    end

    def websocket_handle(request, state) do
        {:reply, request, state}
    end

    def websocket_info(message, state) do
       {:reply, {:text, message}, state}
    end

    def terminate(reason, _req, state) do
        "termination due to #{reason |> inspect}" |> Logger.info
        protocol = CallProtocol.get_module(%CallProtocol.Janus{})
        protocol.destroy(state)
        :ok
    end

    def push(websocket, message) do
        Logger.info("pushing #{message |> inspect}")
        send(websocket, Poison.encode!(message))

    end
end
