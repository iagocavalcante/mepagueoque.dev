import Config

# Runtime configuration for releases
# This file is executed after compilation in the target system

# Load environment variables from .env file if in development
# In production (Fly.io), environment variables are provided directly
if config_env() == :dev do
  try do
    # Get the path to the .env file relative to the project root
    env_path = Path.join([__DIR__, "..", ".env"])
    Dotenvy.source!([env_path, System.get_env()])
  rescue
    e ->
      IO.warn("Failed to load .env file: #{inspect(e)}")
      :ok
  end
end

# Server configuration
config :mepagueoque_api,
  port: String.to_integer(System.get_env("PORT") || "4000")

# Cloudflare Turnstile configuration
config :mepagueoque_api,
  turnstile_secret: System.get_env("TURNSTILE_SECRET_KEY")

# Giphy API configuration
config :mepagueoque_api,
  giphy_api_key: System.get_env("GIPHY_API_KEY"),
  giphy_url: System.get_env("GIPHY_URL") || "https://api.giphy.com/v1/gifs"

# Resend email service configuration
config :mepagueoque_api,
  resend_api_key: System.get_env("RESEND_API_KEY"),
  from_email: System.get_env("FROM_EMAIL")

# CORS allowed origins configuration
allowed_origins =
  case System.get_env("ALLOWED_ORIGINS") do
    nil -> ["http://localhost:8080", "https://mepagueoque.dev"]
    origins -> String.split(origins, ",")
  end

config :mepagueoque_api,
  allowed_origins: allowed_origins

# Logger configuration based on environment
if config_env() == :prod do
  config :logger, level: :info
else
  config :logger, level: :debug
end

# Configure JSON encoder
config :plug, :json_library, Jason
