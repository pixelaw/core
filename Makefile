
include .account
export

REPO = ghcr.io/pixelaw/core
CORE_VERSION = $(shell cat VERSION)
DOJO_VERSION = $(shell cat DOJO_VERSION)
DOJO_WORLD_ADDRESS = $(shell cat DOJO_WORLD_ADDRESS)

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
		-e DOJO_WORLD_ADDRESS=$(DOJO_WORLD_ADDRESS) \
		-e SERVER_PORT=3000 \
		$(REPO):$(CORE_VERSION)

docker_bash:
	docker run \
		--name pixelaw \
		--rm \
		-ti \
		-p 3000:3000 -p 5050:5050 -p 8080:8080 \
		-e DOJO_WORLD_ADDRESS=$(DOJO_WORLD_ADDRESS) \
		-e SERVER_PORT=3000 \
		$(REPO):$(CORE_VERSION) \
		/bin/bash

build:
	cd contracts;sozo build;

shell:
	docker compose exec keiko bash


test:
	cd contracts; sozo test

