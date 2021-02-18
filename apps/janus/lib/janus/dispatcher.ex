defmodule Janus.Dispatcher do
    @behaviour Janus.DispatcherBehaviour
    use GenServer
    require Logger

    def child_spec(url) do
        %{
            id: __MODULE__,
            start: {__MODULE__, :start_link, [url]},
            type: :worker,
            restart: :permanent
        }
    end

    def start_link(_url) do
        GenServer.start_link(__MODULE__, %{requests: %{}}, name: __MODULE__)
    end

    def init(state) do
        {:ok, state}
    end

    def handle_call({:send, message}, from, %{requests: requests} = state) do
        ref = make_ref()

        transaction_id =
        Janus.Utilities.generate_random_string()

        message
        |> Map.put("transaction", transaction_id)
        |> put_value(state, :remote_session_id, :session_id)
        |> Janus.Socket.send(self(), ref, transaction_id)
        requests = Map.put(requests, ref, from)
        state = Map.put(state, :requests, requests)
        {:noreply, state}
    end

    def handle_call({:set_data, key, value}, _from, state) do
        state = Map.put(state, key, value)
        {:reply, {:ok, key, value}, state}
    end

    def handle_call({:get_data, key}, _from, state) do
        {:reply, state[key], state}
    end

    defp put_value(map = %{}, state, key, target_key) do
        case Map.has_key?(state, key) do
            true -> Map.put(map, target_key, state[key])
            false -> map
        end
    end

    def handle_cast({:response, _ref, %{"janus" => "ack"}}, state) do
        {:noreply, state}
    end

    def handle_cast({:response, ref, %{"janus" => "success", "plugindata" => %{"data" => data}}}, %{requests: requests} = state) do
        {from, requests} = Map.pop(requests, ref)
        GenServer.reply(from, data)
        state = Map.put(state, :requests, requests)
        {:noreply, state}
    end

    def handle_cast({:response, ref, %{"janus" => "event", "plugindata" => %{"data" => data}, "jsep" => jsep}}, %{requests: requests} = state) do
        {from, requests} = Map.pop(requests, ref)
        GenServer.reply(from, %{data: data, jsep: jsep})
        state = Map.put(state, :requests, requests)
        {:noreply, state}
    end

    def handle_cast({:response, ref, %{"janus" => "event", "plugindata" => %{"data" => data}}}, %{requests: requests} = state) do
        {from, requests} = Map.pop(requests, ref)
        GenServer.reply(from, data)
        state = Map.put(state, :requests, requests)
        {:noreply, state}
    end

    def handle_cast({:response, _ref, %{"janus" => "error", "error" => %{"code" => code, "reason" => reason} = error}}, %{requests: _requests} = state) do
        "Error #{code}: #{reason}" |> Logger.info
        Janus.DispatcherErrorHandler.handle_error(error)
        {:noreply, state}
    end


    def handle_cast({:response, ref, response}, %{requests: requests} = state) do
        {from, requests} = Map.pop(requests, ref)
        GenServer.reply(from, response)
        state = Map.put(state, :requests, requests)
        {:noreply, state}
    end



    def handle_info({:keep_alive, session_id}, state) do
        message = Janus.Messages.create_keep_alive_message(session_id) |> Map.put(:transaction, Janus.Utilities.generate_random_string())
        Janus.Socket.send_keepalive(message)
        Janus.KeepAlivePulse.queue_keep_alive(session_id)
        {:noreply, state}
    end

    def process_response(response) do
        GenServer.cast(__MODULE__, {:response, response})
    end

    def send_message(message) do
        GenServer.call(__MODULE__, {:send, message})
    end

    def set_data(key, value) do
        GenServer.call(__MODULE__, {:set_data, key, value})
    end

    def get_data(key) do
        GenServer.call(__MODULE__, {:get_data, key})
    end

    def implementation, do: Application.fetch_env!(:janus, :dispatcher)
end
