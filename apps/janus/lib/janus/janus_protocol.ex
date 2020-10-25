defimpl CallProtocol, for: CallProtocol.Janus do
    def get_module(protocol_type) do
        Janus.CommandRouter
    end
end