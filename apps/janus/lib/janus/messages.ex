defmodule Janus.Messages do
    @spec create_session_message :: %{janus: <<_::48>>}
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

    def create_room_message(room_id, handle_id, permanent? \\ false) do
        %{
            janus: "message",
            body: %{
                request: "create",
                permanent: permanent?,
                room: room_id
            },
            handle_id: handle_id
        }
    end

    def list_rooms_message(handle_id) do
        %{
            janus: "message",
            body: %{
                request: "list"
            },
            handle_id: handle_id
        }
    end

    def join_room_message(room_id, participant_id, handle_id, type \\ "publisher") do
        %{
            janus: "message",
            body: %{
                request: "join",
                ptype: type,
                room: room_id,
                id: participant_id
            },
            handle_id: handle_id
        }
    end

    def publish_message(handle_id, sdp, sdp_type \\ "offer") do
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
            },
            handle_id: handle_id
        }
    end

    @spec join_message(any, any, any) :: %{
            body: %{feed: any, ptype: <<_::80>>, request: <<_::32>>, room: any},
            handle_id: any,
            janus: <<_::56>>
          }
    def join_message(room_id, publisher_id, handle_id) do
        %{
            janus: "message",
            body: %{
                request: "join",
                ptype: "subscriber",
                room: room_id,
                feed: publisher_id
            },
            handle_id: handle_id
        }
    end

    @spec leave_message(any) :: %{body: %{request: <<_::40>>}, handle_id: any, janus: <<_::56>>}
    def leave_message(handle_id) do
        %{
            janus: "message",
            body: %{
                request: "leave"
            },
            handle_id: handle_id
        }
    end


    @spec start_message(any, any, any) :: %{
            body: %{request: <<_::40>>},
            handle_id: any,
            janus: <<_::56>>,
            jsep: %{sdp: any, trickle: true, type: <<_::48>>}
          }
    def start_message(sdp, _sdp_type, handle_id) do
        %{
            janus: "message",
            body: %{
                request: "start"
            },
            jsep: %{
                sdp: sdp,
                trickle: true,
                type: "answer"
            },
            handle_id: handle_id
        }
    end

    def trickle_message(sdp_mid, sdp_mline_index, candidate) do
        %{
            janus: "trickle",
            candidate: %{
                sdpMid: sdp_mid,
                sdpMLineIndex: sdp_mline_index,
                candidate: candidate
            }
        }
    end
end
