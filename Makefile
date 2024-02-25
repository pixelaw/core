
include .account
export

REPO = ghcr.io/pixelaw/core
CORE_VERSION = 0.1.5
KEIKO_VERSION = v0.1.5


docker_build:
	echo $$private_key && \
	docker build -t $(REPO):$(CORE_VERSION) -t $(REPO):latest \
	--build-arg KEIKO_VERSION=$(KEIKO_VERSION) \
	--secret id=DOJO_KEYSTORE_PASSWORD \
	--progress=plain .

docker_run:
	docker run -p 3000:3000 -p 5050:5050 -p 8080:8080 $(REPO):$(CORE_VERSION)

build:
	cd contracts;sozo build;
#	cp contracts/target/dev/manifest.json web/src/dojo/manifest.json;
#	node web/src/generateComponents.cjs;
#	cp web/src/output.ts web/src/dojo/contractComponents.ts

shell:
	docker run -it --rm --name temp-container pixelaw/core:latest bash


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

