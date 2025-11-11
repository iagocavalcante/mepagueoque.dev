import Config

# Production-specific configuration
# Runtime configuration (API keys, etc.) is now in runtime.exs

# Set info level logging in production
config :logger, level: :info

# Configure logger backend for production
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
