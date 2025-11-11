# Multi-stage Dockerfile for Elixir application

# Build stage
FROM hexpm/elixir:1.17.2-erlang-27.0.1-debian-bookworm-20240722-slim AS build

# Install build dependencies
RUN apt-get update -y && \
    apt-get install -y build-essential git && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build environment
ENV MIX_ENV=prod

# Copy mix files
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy config files
COPY config/config.exs config/${MIX_ENV}.exs config/runtime.exs config/
RUN mix deps.compile

# Copy application source
COPY lib lib
COPY .formatter.exs .

# Compile application
RUN mix compile

# Build release
RUN mix release

# Release stage
FROM hexpm/elixir:1.17.2-erlang-27.0.1-debian-bookworm-20240722-slim

# Install runtime dependencies
RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates curl && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create app user
RUN useradd --create-home app
WORKDIR /home/app

# Copy release from build stage
COPY --from=build --chown=app:app /app/_build/prod/rel/mepagueoque_api /home/app/

# Switch to app user
USER app

# Set environment
ENV PORT=8080

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the release
CMD ["/home/app/bin/mepagueoque_api", "start"]
