defmodule MepagueoqueApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :mepagueoque_api,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        mepagueoque_api: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto, :inets],
      mod: {MepagueoqueApi.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Web server and HTTP framework
      {:plug, "~> 1.16"},
      {:bandit, "~> 1.6"},
      {:plug_cowboy, "~> 2.7"},

      # HTTP client
      {:req, "~> 0.5"},

      # Email service (using Req for Resend API)
      # {:resend, "~> 0.5"},

      # JSON encoding/decoding
      {:jason, "~> 1.4"},

      # CORS support
      {:cors_plug, "~> 3.0"},

      # Configuration
      {:dotenvy, "~> 0.8"}
    ]
  end
end
