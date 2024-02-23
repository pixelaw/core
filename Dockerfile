FROM node:20-bookworm-slim as web_node_deps

WORKDIR /app
COPY /web/patches ./patches
COPY --link /web/package.json ./package.json
COPY --link /web/yarn.lock ./yarn.lock

# Install dependencies
RUN yarn install --frozen-lockfile

FROM node:20-bookworm-slim as bots_node_deps
WORKDIR /app
COPY --link /bots/package.json ./package.json
COPY --link /bots/yarn.lock ./yarn.lock

# Install dependencies
RUN yarn install --frozen-lockfile

# Now copy all the sources so we can compile
FROM node:20-bookworm-slim AS web_node_builder
WORKDIR /app
COPY /web .
COPY --from=web_node_deps /app/node_modules ./node_modules

# Build the webapp
RUN yarn build --mode production



FROM ghcr.io/pixelaw/keiko:0.1.7 AS runtime

ENV PUBLIC_TORII=http://localhost:8080
ENV PUBLIC_NODE_URL=http://localhost:5050
ENV VITE_PUBLIC_ETH_CONTRACT_ADDRESS=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
ENV CORE_VERSION=VERSION

HEALTHCHECK CMD (curl --fail http://localhost:3000 && curl --fail http://localhost:5050) || exit 1

WORKDIR /tmp/contracts
COPY ./contracts /tmp/contracts
RUN sozo build --manifest-path Scarb.toml && \
    bash scripts/create_genesis.sh

RUN mkdir /keiko/config && mkdir -p /keiko/storage/manifests && mkdir /keiko/log &&  \
    cp genesis.json /keiko/config/genesis.json && \
    cp target/dev/manifest.json /keiko/config/manifest.json && \
    cp target/dev/manifest.json /keiko/storage/manifests/core.json && \
    cp torii.sqlite /keiko/storage/torii.sqlite && \
    touch /keiko/log/katana.log.json && touch /keiko/log/torii.log

RUN rm -rf /tmp/contracts

WORKDIR /keiko

COPY --link ./startup.sh ./startup.sh
COPY --from=web_node_builder /app/dist static/
COPY --link ./web/.env.example .env.core.example


COPY ./bots ./bots
COPY --link ./bots/.env.production ./bots/.env
COPY --from=bots_node_deps /app/node_modules ./bots/node_modules




LABEL org.opencontainers.image.description = "PixeLAW core container"


CMD ["bash", "./startup.sh"]
