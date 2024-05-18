
# Stage 4: Install runtime
FROM node:22-bookworm-slim as dojo

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    jq \
    git \
    procps \
#    git-all \
#    build-essential \
    nano \
    net-tools \
    cargo \
    sqlite3 \
    curl \
    zip  && \
    apt-get autoremove && apt-get clean

#Install Scarb
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh --output install.sh
RUN chmod +x ./install.sh
RUN export PATH=$HOME/.local/bin:$PATH && ./install.sh
RUN echo 'export PATH=$HOME/.local/bin:$PATH' >> $HOME/.bashrc
ENV PATH="/root/.local/bin:${PATH}"

ARG DOJO_VERSION
RUN if [ -z "$DOJO_VERSION" ]; then echo "DOJO_VERSION argument is required" && exit 1; fi


# Install dojo
SHELL ["/bin/bash", "-c"]
RUN curl -L https://install.dojoengine.org | bash
RUN source ~/.bashrc
ENV PATH="/root/.dojo/bin:${PATH}"
RUN dojoup -v $DOJO_VERSION

# Install starkli
SHELL ["/bin/bash", "-c"]
RUN curl https://get.starkli.sh | bash
RUN source ~/.bashrc
ENV PATH="/root/.starkli/bin:${PATH}"
RUN starkliup




# Stage 4: Setup runtime
FROM dojo AS builder
ENV PUBLIC_TORII=http://localhost:8080
ENV STARKNET_RPC=http://localhost:5050
ENV CORE_VERSION=VERSION
ENV VITE_PUBLIC_ETH_CONTRACT_ADDRESS=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
HEALTHCHECK CMD curl --fail http://localhost:3000 && \
                curl --fail http://localhost:5050 && \
                curl --fail http://localhost:8080 || \
                exit 1

COPY ./dojo_init /tmp/dojo_init
COPY ./contracts/Scarb.toml /tmp/dojo_init

# Run build separately to cache the dojo/scarb dependencies
RUN cd /tmp/dojo_init && sozo build
RUN mkdir -p /tmp/contracts
COPY ./contracts /tmp/contracts

WORKDIR /tmp/contracts

## Generate genesis.json for EMPTY core
RUN \
    --mount=type=secret,id=DOJO_KEYSTORE_PASSWORD \
    export DOJO_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
    export STARKNET_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
    bash scripts/create_snapshot.sh dev && \
    WORLD_ADDRESS=$(jq -r '.world.address' manifests/dev/manifest.json) && \
    echo $WORLD_ADDRESS && \
    mkdir -p /pixelaw/storage_init/$WORLD_ADDRESS && \
    cp out/dev/genesis.json /pixelaw/storage_init/$WORLD_ADDRESS/genesis.json && \
    cp out/dev/katana_db.zip /pixelaw/storage_init/$WORLD_ADDRESS/katana_db.zip && \
    cp out/dev/torii.sqlite.zip /pixelaw/storage_init/$WORLD_ADDRESS/torii.sqlite.zip && \
    rm -rf out/dev


## Generate genesis.json for POPULATED core
RUN \
    --mount=type=secret,id=DOJO_KEYSTORE_PASSWORD \
    export DOJO_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
    export STARKNET_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
    bash scripts/create_snapshot.sh dev-pop && \
    WORLD_ADDRESS=$(jq -r '.world.address' manifests/dev-pop/manifest.json) && \
    echo $WORLD_ADDRESS && \
    mkdir -p /pixelaw/storage_init/$WORLD_ADDRESS && \
    cp out/dev-pop/genesis.json /pixelaw/storage_init/$WORLD_ADDRESS/genesis.json && \
    cp out/dev-pop/katana_db.zip /pixelaw/storage_init/$WORLD_ADDRESS/katana_db.zip && \
    cp out/dev-pop/torii.sqlite.zip /pixelaw/storage_init/$WORLD_ADDRESS/torii.sqlite.zip && \
    rm -rf out/dev-pop



# Stage 1: Install bots_node_deps
FROM node:20-bookworm-slim as bots_node_deps
WORKDIR /app
COPY /bots/package.json ./package.json
COPY /bots/yarn.lock ./yarn.lock
RUN apt-get update && apt-get install -y build-essential python3 && \
    yarn install --frozen-lockfile

# Stage 2: Put the webapp files in place
FROM ghcr.io/pixelaw/web:0.2.16 AS web_node_builder


FROM dojo as runner

WORKDIR /pixelaw
COPY --from=web_node_builder /app/dist static/
COPY ./startup.sh ./startup.sh
COPY ./bots ./bots
COPY ./bots/.env.production ./bots/.env
COPY --from=bots_node_deps /app/node_modules ./bots/node_modules

COPY --from=builder /pixelaw .


LABEL org.opencontainers.image.description = "PixeLAW core container"
CMD ["bash", "./startup.sh"]

