
# Stage 1: Install bots_node_deps
FROM node:20-bookworm-slim as bots_node_deps
WORKDIR /app
COPY /bots/package.json ./package.json
COPY /bots/yarn.lock ./yarn.lock
RUN apt-get update && apt-get install -y build-essential python3 && \
    yarn install --frozen-lockfile

# Stage 2: Put the webapp files in place
FROM ghcr.io/pixelaw/web:0.2.16 AS web_node_builder


# Stage 4: Setup runtime
FROM ghcr.io/pixelaw/keiko:0.2.6 AS runtime
ENV PUBLIC_TORII=http://localhost:8080
ENV STARKNET_RPC=http://localhost:5050
ENV CORE_VERSION=VERSION
ENV VITE_PUBLIC_ETH_CONTRACT_ADDRESS=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
HEALTHCHECK CMD curl --fail http://localhost:3000 && \
                curl --fail http://localhost:5050 && \
                curl --fail http://localhost:8080 || \
                exit 1


RUN apt-get install sqlite3 -y && \
    mkdir -p storage_init/config storage_init/manifests log && \
    touch log/katana.log.json log/torii.log log/bots.log && \
    mkdir -p /tmp/contracts && \
    mkdir -p /keiko/storage_init/config && \
    touch /keiko/log/katana.log.json && touch /keiko/log/torii.log && touch /keiko/log/bots.log

COPY ./contracts /tmp/contracts

WORKDIR /tmp/contracts


RUN \
    --mount=type=secret,id=DOJO_KEYSTORE_PASSWORD \
    export DOJO_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
    export STARKNET_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
    bash scripts/create_genesis.sh dev

RUN \
    WORLD_ADDRESS=$(jq -r '.world.address' manifests/dev/manifest.json) && \
    mkdir -p /keiko/storage_init/$WORLD_ADDRESS/config && \
    echo $WORLD_ADDRESS && \
    cp out/dev/genesis.json /keiko/storage_init/$WORLD_ADDRESS/config/genesis.json && \
    cp out/dev/torii.sqlite /keiko/storage_init/$WORLD_ADDRESS/torii.sqlite


RUN \
    --mount=type=secret,id=DOJO_KEYSTORE_PASSWORD \
    export DOJO_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
    export STARKNET_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
    bash scripts/create_genesis.sh dev-pop

RUN \
    WORLD_ADDRESS=$(jq -r '.world.address' manifests/dev-pop/manifest.json) && \
    mkdir -p /keiko/storage_init/$WORLD_ADDRESS/config && \
    echo $WORLD_ADDRESS && \
    cp out/dev-pop/genesis.json /keiko/storage_init/$WORLD_ADDRESS/config/genesis.json && \
    cp out/dev-pop/torii.sqlite /keiko/storage_init/$WORLD_ADDRESS/torii.sqlite

RUN rm -rf /tmp/contracts

WORKDIR /keiko
COPY --from=web_node_builder /app/dist static/
COPY ./startup.sh ./startup.sh
COPY ./bots ./bots
COPY ./bots/.env.production ./bots/.env
COPY --from=bots_node_deps /app/node_modules ./bots/node_modules


LABEL org.opencontainers.image.description = "PixeLAW core container"
CMD ["bash", "./startup.sh"]

