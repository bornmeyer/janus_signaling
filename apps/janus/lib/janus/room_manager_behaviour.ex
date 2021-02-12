defmodule Janus.RoomManagerBehaviour do
  @callback create_room(room_id::integer(), existing_rooms::map(), handle_id::integer())::map()
  @callback list_rooms(handle_id::integer())::list()
  @callback join_room(room_id::integer(), participant_id::integer(), handle_id::integer())::any()
end
