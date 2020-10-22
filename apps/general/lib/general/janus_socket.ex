defmodule General.JanusSocket do
    use WebSockex
    require Logger

    def child_spec(url) do
        %{
            id: __MODULE__,
            start: {__MODULE__, :start_link, [url]},
            type: :worker,
            restart: :transient,
            shutdown: 500

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
            extra_headers: extra_headers, name: __MODULE__, handle_initial_conn_failure: true, debug: [:trace])
    end

    def handle_connect(conn, state) do
        Logger.info("connected to #{conn.host}:#{conn.port}")
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
        #|> General.Dispatcher.process_response
        handle_response(message, state)
    end

    def handle_response(%{"janus" => "ack"} = message, state) do
        {:ok, state}
    end
    
    def handle_response(%{"janus" => "webrtcup"} = message, state) do
        {:ok, state}
    end

    def handle_response(%{"janus" => "media"} = message, state) do
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
        requests = state.requests
        {{command, sender, ref}, requests} = Map.pop(requests, transaction_id)
        state = Map.put(state, :requests, requests)

        GenServer.cast(sender, {:response, ref, message})
        {:ok, state}
    end

    def handle_disconnect(%{reason: {:local, reason}}, state) do
        Logger.info("Local close with reason: #{inspect reason}")
        {:error, state}
    end

    def terminate(reason, _req, _state) do
        Logger.info(reason)
        :normal
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