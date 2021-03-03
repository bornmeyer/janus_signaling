defmodule Janus.Participant do
  defstruct id: nil, publishing_plugin: nil, subscribing_plugin: nil

  def update_plugin(participant, plugin, plugin_type) do
    case plugin_type do
      :subscribing_plugin -> %{participant | subscribing_plugin: plugin }
      :publishing_plugin -> %{participant | publishing_plugin: plugin }
      _ -> :error
    end
  end
end
