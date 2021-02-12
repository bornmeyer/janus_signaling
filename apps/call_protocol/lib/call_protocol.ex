defprotocol CallProtocol do
  def get_module(protocol_type)

  def after_connect(connection, state)
end

defmodule CallProtocol.Janus do
  defstruct command: nil, state: nil
end
