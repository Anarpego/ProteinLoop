FROM elixir:1.20.1-otp-28-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config

RUN mix deps.get --only prod

COPY assets assets
COPY lib lib
COPY priv priv

RUN mix compile
RUN mix assets.deploy

ENV PHX_SERVER=true
ENV PORT=4000

EXPOSE 4000

CMD ["mix", "phx.server"]
