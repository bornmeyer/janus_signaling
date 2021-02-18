defmodule Janus.SocketErrorHandler do
  require Logger

  def handle_error(%{"code" => 458}) do
    Janus.DispatcherSetup.setup()
    streams = Janus.StreamManager.get_all_streams()
    for stream <- streams do
      plugin = stream
      |> Janus.Stream.get_participant_id
      |> Janus.PluginManager.get_plugin
      Janus.Stream.destroy(stream, plugin)
    end
  end
end
