defmodule Janus.StreamConfiguration do

  def child_spec(stream_id) do
    %{
      id: "#{stream_id}_configuration",
      start: {__MODULE__, :start_link, [%{stream_id: stream_id, configuration: %{
        audio: true,
        video: true,
        data: true
      }}]},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end

  def start_link(state) do
    Agent.start_link(fn -> state end)
  end

  def init(state) do
    {:ok, state}
  end

  def update(stream_id, audio, video, data) do
    new_config = %{
      audio: audio,
      video: video,
      data: data
    }
    Agent.update(via_tuple(stream_id), fn map -> Map.put(map, :configuration, new_config) end)
  end

  defp via_tuple(id) do
    {:via, Registry, {:stream_configuration_registry, "#{id}_configuration"}}
  end
end
