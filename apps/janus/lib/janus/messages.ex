defmodule Janus.Messages do
    def create_session_message do
        %{
            janus: "create"
        }
    end

    def create_attach_message(session_id, plugin_name \\ "janus.plugin.videoroom") do
        %{
            janus: "attach",
            plugin: plugin_name,
            session_id: session_id
        }
    end

    def create_keep_alive_message(session_id) do
        %{
            janus: "keepalive",
            session_id: session_id
        }
    end

    def create_room_message(room_id, permanent? \\ false) do
        %{
            janus: "message",
            body: %{
                request: "create",
                permanent: permanent?,
                room: room_id
            }
        }
    end

    def list_rooms_message do
        %{
            janus: "message",
            body: %{
                request: "list"
            }
        }
    end

    def join_room_message(room_id, participant_id, type \\ "publisher") do
        %{
            janus: "message",
            body: %{
                request: "join",
                ptype: type,
                room: room_id,
                id: participant_id
            }
        }
    end

    def publish_message(sdp, sdp_type \\ "offer") do
        %{
            janus: "message",
            body: %{
                request: "publish",
                audio: true,
                video: true,
                data: true
            },
            jsep: %{
                sdp: sdp,
                trickle: true,
                type: sdp_type 
            }
        }
    end


end