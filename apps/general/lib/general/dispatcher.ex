defmodule General.Dispatcher do
    use GenServer
    alias General.JanusSocket
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
        children = [
            General.JanusSocket.child_spec(url)
        ]
        {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
        GenServer.start_link(__MODULE__, %{supervisor: pid, requests: %{}}, name: __MODULE__)
    end

    def init(state) do
        {:ok, state}
    end

    def handle_call({:send, message}, from, %{requests: requests} = state) do
        ref = make_ref()

        transaction_id = 
        General.Utilities.generate_random_string() 
        #|> General.TransactionStore.add_transaction(sender)

        message = message 
        |> Map.put("transaction", transaction_id)
        |> put_value(state, :remote_session_id, :session_id)
        |> put_value(state, :handle_id, :handle_id)
        message |> General.JanusSocket.send(self(), ref, transaction_id)
        requests = Map.put(requests, ref, from)
        state = Map.put(state, :requests, requests)

        {:noreply, state}
    end

    defp put_value(map = %{}, state, key, target_key) do
        case Map.has_key?(state, key) do
            true -> Map.put(map, target_key, state[key])
            false -> map
        end
    end

    def handle_cast({:response, ref, %{"janus" => "ack"}}, state) do
        {:noreply, state}
    end

    def handle_cast({:response, ref, %{"janus" => "success", "plugindata" => %{"data" => data}} = response}, %{requests: requests} = state) do
        Logger.info(1)
        {from, requests} = Map.pop(requests, ref)
        GenServer.reply(from, data)
        state = Map.put(state, :requests, requests)
        {:noreply, state}
    end


    def handle_cast({:response, ref, %{"janus" => "event", "plugindata" => %{"data" => data}, "jsep" => jsep} = response}, %{requests: requests} = state) do
        Logger.info(4)
        {from, requests} = Map.pop(requests, ref)
        GenServer.reply(from, %{data: data, jsep: jsep})
        state = Map.put(state, :requests, requests)
        {:noreply, state}
    end

    def handle_cast({:response, ref, %{"janus" => "event", "plugindata" => %{"data" => data}} = response}, %{requests: requests} = state) do
        Logger.info(2)
        {from, requests} = Map.pop(requests, ref)
        GenServer.reply(from, data)
        state = Map.put(state, :requests, requests)
        {:noreply, state}
    end


    def handle_cast({:response, ref, response}, %{requests: requests} = state) do
        Logger.info(3)
        {from, requests} = Map.pop(requests, ref)
        GenServer.reply(from, response)
        state = Map.put(state, :requests, requests)
        {:noreply, state}
    end

    def handle_call({:set_data, key, value}, _from, state) do
        state = Map.put(state, key, value)
        {:reply, {:ok, key, value}, state}
    end

    def handle_info({:keep_alive, session_id}, state) do
        message = General.Messages.create_keep_alive_message(session_id) |> Map.put(:transaction, General.Utilities.generate_random_string())
        General.JanusSocket.send_keepalive(message)
        General.Dispatcher.queue_keep_alive(session_id)
        {:noreply, state}
    end

    def process_response(response) do
        GenServer.cast(__MODULE__, {:response, response})
    end

    def send_message(message) do
        GenServer.call(__MODULE__, {:send, message})
    end

    def queue_keep_alive(session_id, interval \\ 15) do
        Process.send_after(__MODULE__, {:keep_alive, session_id}, interval * 1000)
    end

    def set_data(key, value) do
        GenServer.call(__MODULE__, {:set_data, key, value})
    end
end
