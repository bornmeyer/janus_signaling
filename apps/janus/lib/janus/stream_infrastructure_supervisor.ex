defmodule Janus.StreamInfrastructureSupervisor do
  use Supervisor
  require Logger
  def child_spec(args) do
    %{
      id: args[:id],
      start: {__MODULE__, :start_link, [args]},
      type: :supervisor,
      restart: :transient,
      shutdown: 500
    }
  end

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: via_tuple(args[:id]))
  end

  def init(args) do
    children = [
      Janus.StreamStateGuard.child_spec(args[:id]),
      Janus.Stream.child_spec(args[:id], args[:participant_id], args[:room_id], args[:web_socket], args[:handle_id], args[:type], args[:subscribed_to])
    ]
    Supervisor.init(children, strategy: :one_for_all, max_restarts: 0)
  end

  defp via_tuple(id) do
    {:via, Registry, {:stream_infrastructure_registry, id}}
  end

  def get_stream(pid) do
    {_, stream_pid, _, _} = Supervisor.which_children(pid) |> Enum.find(fn {_, _, _, x} -> x == [Janus.Stream] end)
    stream_pid
  end

  def get_stream_guard(pid) do
    {_, stream_guard_pid, _, _} = Supervisor.which_children(pid) |> Enum.find(fn {_, _, _, x} -> x == [Janus.StreamStateGuard] end)
    stream_guard_pid
  end
end
