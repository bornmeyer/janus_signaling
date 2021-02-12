defmodule Janus.DispatcherBehaviour do
  @callback send_message(message::map())::any()
end
