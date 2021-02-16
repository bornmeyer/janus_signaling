defmodule Janus.StreamStateGuardSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link(_args) do
      DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
      DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(stream_id) do
      child_spec = Janus.StreamStateGuard.child_spec(stream_id)
      {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
      pid
  end
end
