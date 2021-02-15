defimpl CallProtocol, for: CallProtocol.Janus do
    @spec get_module(any) :: Janus.CommandRouter
    def get_module(_protocol_type) do
        Janus.CommandRouter
    end
end
