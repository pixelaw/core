
# Stage 1: Install bots_node_deps
FROM node:20-bookworm-slim as bots_node_deps
WORKDIR /app
COPY /bots/package.json ./package.json
COPY /bots/yarn.lock ./yarn.lock
RUN apt-get update && apt-get install -y build-essential python3 && \
    yarn install --frozen-lockfile

# Stage 2: Put the webapp files in place
FROM ghcr.io/pixelaw/web:0.2.15 AS web_node_builder


# Stage 4: Setup runtime
FROM ghcr.io/pixelaw/keiko:0.2.0 AS runtime
ENV PUBLIC_TORII=http://localhost:8080
ENV STARKNET_RPC=http://localhost:5050
ENV CORE_VERSION=VERSION
ENV VITE_PUBLIC_ETH_CONTRACT_ADDRESS=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
HEALTHCHECK CMD curl --fail http://localhost:3000 && \
                curl --fail http://localhost:5050 && \
                curl --fail http://localhost:8080 || \
                exit 1
WORKDIR /keiko
RUN apt-get install sqlite3 -y && \
    mkdir -p storage_init/config storage_init/manifests log && \
    touch log/katana.log.json log/torii.log log/bots.log
COPY ./contracts /tmp/contracts
COPY ./startup.sh ./startup.sh


COPY --from=web_node_builder /app/dist static/

COPY ./bots ./bots
COPY ./bots/.env.production ./bots/.env

COPY --from=bots_node_deps /app/node_modules ./bots/node_modules

LABEL org.opencontainers.image.description = "PixeLAW core container"
CMD ["bash", "./startup.sh"]
