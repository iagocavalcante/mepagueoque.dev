import Config

# Configure JSON encoder
config :plug, :json_library, Jason

# Configure logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment-specific configuration
import_config "#{config_env()}.exs"
