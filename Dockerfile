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


#FROM debian:bookworm-slim as dojoengine
#
## Install dependencies
#RUN apt-get update && \
#    apt-get install -y \
#    jq \
#    git-all \
#    build-essential \
#    curl
#RUN apt-get autoremove && apt-get clean
#
#ARG DOJO_VERSION
#ARG CACHEBUST=1
#
##Install Scarb
#RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh --output install.sh
#RUN chmod +x ./install.sh
#RUN export PATH=$HOME/.local/bin:$PATH && ./install.sh
#RUN echo 'export PATH=$HOME/.local/bin:$PATH' >> $HOME/.bashrc
#ENV PATH="/root/.local/bin:${PATH}"
#
## Install dojo
#SHELL ["/bin/bash", "-c"]
#RUN curl -L https://install.dojoengine.org/ | bash
#RUN source ~/.bashrc
#ENV PATH="/root/.dojo/bin:${PATH}"
#RUN ~/.dojo/bin/dojoup -v $DOJO_VERSION




FROM oostvoort/keiko:v0.0.7 AS runtime

# Build the core contracts
WORKDIR /core/contracts
COPY /contracts .

#COPY ./contracts/Scarb.toml contracts/Scarb.toml
#COPY ./contracts/scripts contracts/scripts

RUN sozo build

WORKDIR /core/web
COPY --from=web_node_builder /app/dist static/



WORKDIR /core/bots
COPY ./bots/ .
COPY ./bots/.env.production ./bots/.env
COPY --from=bots_node_deps /app/node_modules ./bots/node_modules

HEALTHCHECK CMD (curl --fail http://localhost:3000 && curl --fail http://localhost:5050) || exit 1

WORKDIR /keiko

COPY ./startup.sh ./startup.sh

CMD ["bash", "./startup.sh"]
