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

ARG THREE_VERSION=0.185.1
ARG THREE_TARBALL_SHA512=e5aa231425cac278c1459bd49eddd615f11cbd426090de4b9628d114df7984ccbc595906e08d1035c244f8eb96bee2746ce752b6b6df5e7d2991debf43288096
RUN mkdir -p assets/node_modules/three \
  && curl -fsSL "https://registry.npmjs.org/three/-/three-${THREE_VERSION}.tgz" -o /tmp/three.tgz \
  && echo "${THREE_TARBALL_SHA512}  /tmp/three.tgz" | sha512sum -c - \
  && tar -xzf /tmp/three.tgz --strip-components=1 -C assets/node_modules/three \
  && rm /tmp/three.tgz

COPY assets assets
COPY lib lib
COPY priv priv

RUN mix compile
RUN mix assets.deploy

ENV PHX_SERVER=true
ENV PORT=4000

EXPOSE 4000

CMD ["mix", "phx.server"]
