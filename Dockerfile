
# Since glibc in bookworm is too old for dojo, have to make our own nodejs based on ubuntu
# TODO: Replace FROM node:23-bookworm-slim AS dojo

FROM sitespeedio/node:ubuntu-24-04-nodejs-22.13.0 AS nodejs
RUN npm install -g yarn


FROM nodejs AS dojo

SHELL ["/bin/bash", "-c"]

ARG ASDF_VERSION="v0.14.1"
ARG SCARB_VERSION="2.9.2"
ARG DOJO_VERSION="1.3.0"
ARG STARKLI_VERSION="0.3.5"


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

RUN \
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch ${ASDF_VERSION} && \
    chmod +x $HOME/.asdf/asdf.sh && \
    echo "$HOME/.asdf/asdf.sh" >> ~/.bashrc && \
    source ~/.bashrc

ENV PATH="/root/.asdf/bin:/root/.asdf/shims:${PATH}"

RUN \
    asdf plugin add scarb && \
    asdf install scarb ${SCARB_VERSION} && \
    asdf global scarb ${SCARB_VERSION}

RUN \
    asdf plugin add dojo https://github.com/pixelaw/asdf-dojo && \
    asdf install dojo ${DOJO_VERSION} && \
    asdf global dojo ${DOJO_VERSION}


# Install starkli
# TODO right now getting 0.1.6 because newer seems not to be compatible with katana's JSON-RPC
SHELL ["/bin/bash", "-c"]
RUN curl https://get.starkli.sh | bash
RUN source ~/.bashrc
ENV PATH="/root/.starkli/bin:${PATH}"
RUN starkliup -v ${STARKLI_VERSION}



# Stage 2: Put the webapp files in place
FROM ghcr.io/pixelaw/vanilla:0.6.11 AS web

FROM ghcr.io/pixelaw/server:0.5.1 AS server


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

COPY ./dojo_init /pixelaw/contracts/dojo_init
COPY ./contracts/dojo_dev.toml /pixelaw/contracts/dojo_init
COPY ./contracts/Scarb.toml /pixelaw/contracts/dojo_init
COPY ./contracts/Scarb.lock /pixelaw/contracts/dojo_init


# Run build separately to cache the dojo/scarb dependencies

RUN --mount=type=cache,id=scarb_cache,target=/root/.cache/scarb \
    cd /pixelaw/contracts/dojo_init && sozo build


COPY ./contracts /pixelaw/contracts

WORKDIR /pixelaw/contracts

## Generate storage_init
RUN \
    --mount=type=cache,id=scarb_cache,target=/root/.cache/scarb \
    --mount=type=secret,id=DOJO_KEYSTORE_PASSWORD \
    bash scripts/create_snapshot_docker.sh dev


# Install the final system

WORKDIR /pixelaw
COPY --from=web /pixelaw/web/ /pixelaw/web/
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
