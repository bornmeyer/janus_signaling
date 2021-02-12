defprotocol CallProtocol do
  def get_module(protocol_type)
end

defmodule CallProtocol.Janus do
  defstruct command: nil, state: nil
end
