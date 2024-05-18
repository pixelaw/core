
include .account
export

REPO = ghcr.io/pixelaw/core
CORE_VERSION = $(shell cat VERSION)
DOJO_VERSION = $(shell cat DOJO_VERSION)


docker_build:
	echo $$private_key && \
	docker build -t $(REPO):$(CORE_VERSION) -t $(REPO):latest \
	--build-arg DOJO_VERSION=$(DOJO_VERSION) \
	--secret id=DOJO_KEYSTORE_PASSWORD \
  --network=host \
	--progress=plain .

docker_run:
	docker run \
		--name pixelaw \
		--rm \
		-ti \
		-p 3000:3000 -p 5050:5050 -p 8080:8080 \
		-e WORLD_ADDRESS=0xfc685b398bc4692ab3a4acd380859e71f97d2c319f188854d3a01948ba276a \
		$(REPO):$(CORE_VERSION)

build:
	cd contracts;sozo build;
#	cp contracts/target/dev/manifest.json web/src/dojo/manifest.json;
#	node web/src/generateComponents.cjs;
#	cp web/src/output.ts web/src/dojo/contractComponents.ts

shell:
	docker compose exec keiko bash


test:
	cd contracts; sozo test

prep_web:
	cd web; cp .env.example .env

start_keiko: stop_keiko
	make build
	docker compose up -d

restart_keiko: build
	docker compose down -v && docker compose up -d && docker compose logs -f

stop_keiko:
	docker compose down


redeploy:
	@cd contracts; \
	WORLD_ADDR=$$(tail -n1 ../last_deployed_world); \
	sozo migrate --world $$WORLD_ADDR;

deploy:
	@cd contracts; \
	SOZO_OUT="$$(sozo migrate)"; echo "$$SOZO_OUT"; \
	WORLD_ADDR="$$(echo "$$SOZO_OUT" | grep "Successfully migrated World at address" | rev | cut -d " " -f 1 | rev)"; \
	[ -n "$$WORLD_ADDR" ] && \
		echo "$$WORLD_ADDR" > ../last_deployed_world && \
		echo "$$SOZO_OUT" > ../deployed.log; \
	WORLD_ADDR=$$(tail -n1 ../last_deployed_world); \

log_katana:
	docker compose exec keiko tail -f /keiko/log/katana.log.json

log_torii:
	docker compose exec keiko tail -f /keiko/log/torii.log -n 200

