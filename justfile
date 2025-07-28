# Load environment variables from ./.account

set dotenv-load := true
set dotenv-path := "./.account"

# Repository configuration

repo := "ghcr.io/pixelaw/core"
core_version := `cat VERSION`
dojo_version := `cat DOJO_VERSION`

# Build Docker image with populated data
docker-build-populate:
    @echo $private_key
    docker build -f populate.Dockerfile -t {{ repo }}:{{ core_version }}-populated \
        --build-arg DOJO_VERSION={{ dojo_version }} \
        --build-arg GENERATE_POPULATED_CORE=false \
        --secret id=DOJO_KEYSTORE_PASSWORD \
        --network=host \
        --pull=false \
        --progress=plain .

# Build Docker image
docker-build:
    @echo $private_key
    docker build -t {{ repo }}:{{ core_version }} -t {{ repo }}:latest \
        --build-arg DOJO_VERSION={{ dojo_version }} \
        --build-arg GENERATE_POPULATED_CORE=false \
        --secret id=DOJO_KEYSTORE_PASSWORD \
        --network=host \
        --pull=false \
        --progress=plain .

# Run Docker container with default ports
docker-run:
    docker run \
        --name pixelaw \
        --rm \
        -ti \
        -p 3000:3000 -p 5050:5050 -p 8080:8080 \
        -e WORLD_ADDRESS=0x60916a73fe631fcba3b2a930e21c6f7bb2533ea398c7bfa75c72f71a8709fc2 \
        -e SERVER_PORT=3000 \
        {{ repo }}:{{ core_version }}

# Run Docker container with bash shell
docker-bash:
    docker run \
        --name pixelaw \
        --rm \
        -ti \
        -p 3000:3000 -p 5050:5050 -p 8080:8080 \
        -e WORLD_ADDRESS=0xfc685b398bc4692ab3a4acd380859e71f97d2c319f188854d3a01948ba276a \
        -e SERVER_PORT=3000 \
        {{ repo }}:{{ core_version }} \
        /bin/bash

# Build contracts
build:
    cd contracts && sozo build

# Access running Keiko container shell
shell:
    docker compose exec keiko bash

# Run contract tests
test:
    cd pixelaw_testing && sozo test
