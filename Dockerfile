
# Stage 4: Install runtime
FROM node:22-bookworm-slim AS dojo

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    jq \
    git \
    procps \
    nano \
    net-tools \
    sqlite3 \
    curl \
    build-essential \
    make \
    zip  && \
    apt-get autoremove && apt-get clean

RUN yarn global add ts-node pm2

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"


ARG DOJO_VERSION
RUN if [ -z "$DOJO_VERSION" ]; then echo "DOJO_VERSION argument is required" && exit 1; fi


# Install dojo
SHELL ["/bin/bash", "-c"]
RUN curl -L https://install.dojoengine.org | bash
RUN source ~/.bashrc
ENV PATH="/root/.dojo/bin:${PATH}"
RUN dojoup -v $DOJO_VERSION

# Install starkli
# TODO right now getting 0.1.6 because newer seems not to be compatible with katana's JSON-RPC
SHELL ["/bin/bash", "-c"]
RUN curl https://get.starkli.sh | bash
RUN source ~/.bashrc
ENV PATH="/root/.starkli/bin:${PATH}"
RUN starkliup -v 0.1.6

#Install Scarb
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | bash -s -- -v 2.7.0
#RUN chmod +x ./install.sh
#RUN export PATH=$HOME/.local/bin:$PATH && ./install.sh
RUN echo 'export PATH=$HOME/.local/bin:$PATH' >> $HOME/.bashrc
ENV PATH="/root/.local/bin:${PATH}"



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
COPY ./contracts/Scarb.lock /tmp/dojo_init

# Run build separately to cache the dojo/scarb dependencies

RUN --mount=type=cache,id=scarb_cache,target=/root/.cache/scarb \
    cargo --version && \
    cd /tmp/dojo_init && sozo build
RUN mkdir -p /tmp/contracts

COPY ./contracts /tmp/contracts

WORKDIR /tmp/contracts

## Generate genesis.json for EMPTY core
RUN \
    --mount=type=cache,id=scarb_cache,target=/root/.cache/scarb \
    --mount=type=secret,id=DOJO_KEYSTORE_PASSWORD \
    export DOJO_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
    export STARKNET_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
    bash scripts/create_snapshot.sh dev && \
    WORLD_ADDRESS=$(jq -r '.world.address' manifests/dev/deployment/manifest.json) && \
    echo $WORLD_ADDRESS && \
    mkdir -p /pixelaw/storage_init/$WORLD_ADDRESS && \
    cp out/dev/genesis.json /pixelaw/storage_init/$WORLD_ADDRESS/genesis.json && \
    cp manifests/dev/deployment/manifest.json /pixelaw/storage_init/$WORLD_ADDRESS/manifest.json && \
    cp out/dev/katana_db.zip /pixelaw/storage_init/$WORLD_ADDRESS/katana_db.zip && \
    cp out/dev/torii.sqlite.zip /pixelaw/storage_init/$WORLD_ADDRESS/torii.sqlite.zip && \
    rm -rf out/dev


### Generate genesis.json for POPULATED core
#RUN \
#    --mount=type=secret,id=DOJO_KEYSTORE_PASSWORD \
#    export DOJO_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
#    export STARKNET_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD) && \
#    bash scripts/create_snapshot.sh dev-pop && \
#    WORLD_ADDRESS=$(jq -r '.world.address' manifests/dev-pop/deployment/manifest.json) && \
#    echo $WORLD_ADDRESS && \
#    mkdir -p /pixelaw/storage_init/$WORLD_ADDRESS && \
#    cp out/dev-pop/genesis.json /pixelaw/storage_init/$WORLD_ADDRESS/genesis.json && \
#    cp out/dev-pop/katana_db.zip /pixelaw/storage_init/$WORLD_ADDRESS/katana_db.zip && \
#    cp out/dev-pop/torii.sqlite.zip /pixelaw/storage_init/$WORLD_ADDRESS/torii.sqlite.zip && \
#    rm -rf out/dev-pop


# Stage 2: Put the webapp files in place
FROM ghcr.io/pixelaw/web:0.3.10 AS web

FROM ghcr.io/pixelaw/server:0.3.19 AS server


FROM dojo AS runner

WORKDIR /pixelaw
COPY --from=builder /root/ /root/
COPY --from=builder /pixelaw .
COPY --from=web /app/dist /pixelaw/web/
COPY --from=server /app server/

COPY docker/scripts/ /pixelaw/scripts/
COPY docker/ecosystem.config.js /pixelaw/core/docker/
COPY docker/.env.example /pixelaw/core/docker/
COPY docker/.bashrc /root/
COPY ./tools/ /pixelaw/tools/

RUN mkdir /pixelaw/log

LABEL org.opencontainers.image.description="PixeLAW core container"

EXPOSE 5050
EXPOSE 8080
EXPOSE 3000

CMD ["bash", "./scripts/startup.sh"]
