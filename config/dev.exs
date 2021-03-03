import Config
config :janus, dispatcher: Janus.Dispatcher
config :janus, room_manager: Janus.RoomManager

#config :logger,
#  format: "$message\n",
#  level: String.to_atom(System.get_env("LOG_LEVEL") || "info"),
#  handle_otp_reports: true,
#  handle_sasl_reports: true
