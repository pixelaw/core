
include .account
export

REPO = ghcr.io/pixelaw/core
CORE_VERSION = $(shell cat VERSION)
DOJO_VERSION = $(shell cat DOJO_VERSION)


docker_build_populate:
	echo $$private_key && \
	docker build -f populate.Dockerfile -t $(REPO):$(CORE_VERSION)-populated \
	--build-arg DOJO_VERSION=$(DOJO_VERSION)  \
	--build-arg GENERATE_POPULATED_CORE=false  \
	--secret id=DOJO_KEYSTORE_PASSWORD \
  --network=host \
   --pull=false \
	--progress=plain .

docker_build:
	echo $$private_key && \
	docker build -t $(REPO):$(CORE_VERSION) -t $(REPO):latest \
	--build-arg DOJO_VERSION=$(DOJO_VERSION)  \
	--build-arg GENERATE_POPULATED_CORE=false  \
	--secret id=DOJO_KEYSTORE_PASSWORD \
  --network=host \
   --pull=false \
	--progress=plain .

docker_run:
	docker run \
		--name pixelaw \
		--rm \
		-ti \
		-p 3000:3000 -p 5050:5050 -p 8080:8080 \
		-e WORLD_ADDRESS=0x60916a73fe631fcba3b2a930e21c6f7bb2533ea398c7bfa75c72f71a8709fc2 \
		-e SERVER_PORT=3000 \
		$(REPO):$(CORE_VERSION)

docker_bash:
	docker run \
		--name pixelaw \
		--rm \
		-ti \
		-p 3000:3000 -p 5050:5050 -p 8080:8080 \
		-e WORLD_ADDRESS=0xfc685b398bc4692ab3a4acd380859e71f97d2c319f188854d3a01948ba276a \
		-e SERVER_PORT=3000 \
		$(REPO):$(CORE_VERSION) \
		/bin/bash

build:
	cd contracts;sozo build;

shell:
	docker compose exec keiko bash


test:
	cd contracts; sozo test

