defmodule Janus.Socket do
    use WebSockex
    require Logger

    def child_spec(url) do
        %{
            id: __MODULE__,
            start: {__MODULE__, :start_link, url},
            type: :worker,
            restart: :permanent
        }
    end

    def start_link(url) do
        Logger.info("starting socket for #{url}")
        state = %{
            requests: %{},
            transaction_ids: []
        }
        extra_headers = [
            {"Sec-WebSocket-Protocol", "janus-protocol",}
        ]
        WebSockex.start_link(url, __MODULE__, state,
            extra_headers: extra_headers, name: __MODULE__, handle_initial_conn_failure: false, async: true)# debug: [:trace])
    end

    def handle_connect(conn, state) do
        Logger.info("connected to #{conn.host}:#{conn.port}")
        Janus.DispatcherSetup.setup()
        {:ok, state}
    end

    def handle_cast({:request, json, sender, ref, transaction_id}, %{requests: requests, transaction_ids: transaction_ids} = state) do
        requests = Map.put(requests, transaction_id, {:request, sender, ref})
        state = state
        |> Map.put(:requests, requests)
        |> Map.put(:transaction_ids, [transaction_id | transaction_ids])
        {:reply, {:text, json}, state}
    end

    def handle_frame({:text, message}, state) do
        message = message
        |> Poison.decode!
        handle_response(message, state)
    end

    def handle_response(%{"janus" => "ack"}, state) do
        {:ok, state}
    end

    def handle_response(%{"janus" => "webrtcup"} = message, state) do
        Janus.EventRouter.handle_event(message)
        {:ok, state}
    end

    def handle_response(%{"janus" => "media"}, state) do
        {:ok, state}
    end

    def handle_response(%{"janus" => "error", "error" => error}, state) do
        error |> inspect |> Logger.info
        {:ok, state}
    end

    def handle_response(%{"janus" => "hangup", "reason" => reason}, state) do
        reason |> inspect |> Logger.info
        {:ok, state}
    end

    def handle_response(message, state) do
        transaction_id = message["transaction"]
        state =case transaction_id do
            nil -> state
            _ -> process_response(message, transaction_id, state)
        end
        {:ok, state}
    end

    defp process_response(message, transaction_id, state) do
        requests = state.requests
        {{_command, sender, ref}, requests} = Map.pop(requests, transaction_id)
        state = Map.put(state, :requests, requests)

        GenServer.cast(sender, {:response, ref, message})
        state
    end

    def handle_disconnect(disconnect_map, state) do
        disconnect_map |> inspect |> Logger.info
        super(disconnect_map, state)
        #{:ok, state}
    end

    def send(message, sender, ref, transaction_id) do
        json = Poison.encode!(message)
        WebSockex.cast(__MODULE__, {:request, json, sender, ref, transaction_id})
    end

    def send_keepalive(message) do
        json = Poison.encode!(message)
        WebSockex.send_frame(__MODULE__, {:text, json})
    end
end
