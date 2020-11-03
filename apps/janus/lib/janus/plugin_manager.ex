defmodule Janus.PluginManager do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def new(participant_id, room_id) do
    session_id = Janus.Dispatcher.get_data(:remote_session_id)
    %{"data" => %{"id" => handle_id}, "janus" => "success"} = Janus.Dispatcher.send_message(Janus.Messages.create_attach_message(session_id))
    plugin = %Janus.Plugin{handle_id: handle_id, session_id: session_id, participant_id: participant_id, room_id: room_id}
    Agent.update(__MODULE__, fn map -> map |> Map.put(participant_id, plugin) end)
    {:ok, plugin}
  end

  def add_stream(participant_id, stream) do
    {:ok, plugin} = Agent.get(__MODULE__, fn map -> map |> Map.fetch(participant_id) end)
    plugin = case Janus.Stream.get_type(stream) do
      :publisher -> %{plugin | publishing_stream: stream}
      :subscriber -> %{plugin | subscribing_streams: [stream | plugin.subscribing_streams ]}
    end
    Agent.update(__MODULE__, fn map -> map |> Map.put(participant_id, plugin) end)
    {:ok, plugin}
  end

  def get_plugin(participant_id) do
    {:ok, plugin} = Agent.get(__MODULE__, fn map -> map |> Map.fetch(participant_id) end)
    plugin
  end

  def update_plugin(participant_id, plugin) do
    Agent.update(__MODULE__, fn map -> map |> Map.put(participant_id, plugin) end)
  end
end
