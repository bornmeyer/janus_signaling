defmodule General.ClientSideSupervisor do
    use Supervisor
    require Logger

    def child_spec(ip, port) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [ip, port]},
          shutdown: 5_000,
          restart: :transient,
          type: :supervisor
        }
      end

    def start_link(ip, port) do
        Logger.info("restarting client supervisor")
        Supervisor.start_link(__MODULE__, [ip, port], name: __MODULE__)
    end

    def init([ip, port]) do
        children = [
            {
              General.StreamSupervisor, []
            },
            Plug.Cowboy.child_spec(
              scheme: :http,
              plug: General.Router,
              options: [
                dispatch: dispatch(),
                port: 4000
              ]
            ),
            Registry.child_spec(
              keys: :duplicate,
              name: Registry.General
            ),
            General.RoomManager.child_spec(),
            {
              Registry, [keys: :unique, name: :stream_registry]
            }
          ]

          result = Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
          setup()
          result
    end

    defp dispatch do
        [
          {:_,
            [
              {:_, General.SocketHandler, []},
              #{:_, Plug.Cowboy.Handler, {General.Router, []}}
            ]
          }
        ]
    end

    defp setup do
        %{"data" => %{"id" => session_id}, "janus" => "success"} = General.Dispatcher.send_message(General.Messages.create_session_message)
        General.Dispatcher.set_data(:remote_session_id, session_id)
        %{"data" => %{"id" => handle_id}, "janus" => "success"} = General.Dispatcher.send_message(General.Messages.create_attach_message(session_id))
        General.Dispatcher.set_data(:handle_id, handle_id)
        General.Dispatcher.queue_keep_alive(session_id)
    end
end