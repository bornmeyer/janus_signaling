defmodule Janus.TransactionStore do
    use Agent

    def start_link(_) do
        Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def add_transaction(transaction_id, sender) do
        Agent.update(__MODULE__, fn map -> Map.put(map, transaction_id, sender) end)
        transaction_id
    end

    def get_sender_for_transaction(transaction_id) do
        Agent.get(__MODULE__, fn map -> Map.fetch(map, transaction_id) end)
    end
end