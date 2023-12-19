FROM node:18-bookworm-slim as web_node_deps

WORKDIR /app
COPY /web/patches ./patches
COPY /web/package.json ./package.json
COPY /web/yarn.lock ./yarn.lock

# Install dependencies
RUN yarn install --frozen-lockfile

FROM node:18-bookworm-slim as bots_node_deps
WORKDIR /app
COPY /bots/package.json ./package.json
COPY /bots/yarn.lock ./yarn.lock

# Install dependencies
RUN yarn install --frozen-lockfile

# Now copy all the sources so we can compile
FROM node:18-bookworm-slim AS web_node_builder
WORKDIR /app
COPY /web .
COPY --from=web_node_deps /app/node_modules ./node_modules

# Build the webapp
RUN yarn build --mode production



FROM ghcr.io/oostvoort/keiko:0.0.21 AS runtime

ENV PUBLIC_TORII=http://localhost:8080
ENV PUBLIC_NODE_URL=http://localhost:5050
ENV VITE_PUBLIC_ETH_CONTRACT_ADDRESS=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
ENV CORE_VERSION=VERSION

HEALTHCHECK CMD (curl --fail http://localhost:3000 && curl --fail http://localhost:5050) || exit 1

WORKDIR /keiko

COPY ./startup.sh ./startup.sh
COPY --from=web_node_builder /app/dist static/
COPY ./web/.env.example .env.core.example


COPY ./bots ./bots
COPY ./bots/.env.production ./bots/.env
COPY --from=bots_node_deps /app/node_modules ./bots/node_modules

COPY ./contracts ./contracts

LABEL org.opencontainers.image.description = "PixeLAW core container"

RUN sozo build --manifest-path ./contracts/Scarb.toml

CMD ["bash", "./startup.sh"]
