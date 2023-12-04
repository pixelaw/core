REPO = pixelaw/core
CORE_VERSION = v0.0.9
KEIKO_VERSION = v0.0.11


docker_build:
	docker build -t $(REPO):$(CORE_VERSION) -t $(REPO):latest --build-arg KEIKO_VERSION=$(KEIKO_VERSION) --progress=plain .

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

# Update version
# Get the latest tag
VERSION=$(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')

# Define the version type (major, minor, patch)
type ?= patch

# Increment the version based on the version type
NEW_VERSION=$(shell echo $(VERSION) | awk -F. -v type=$(type) 'BEGIN {OFS = FS} \
    {if (type == "major") {$$1=$$1+1; $$2=0; $$3=0} else if (type == "minor") {$$2=$$2+1; $$3=0} else if (type == "patch") $$3=$$3+1} \
    {print $$1"."$$2"."$$3}')

# To use tag make push-tag
# type=patch for patch version, type=minor for minor version, type=major for major version
push-tag:
	echo v$(VERSION) to v$(NEW_VERSION)
	# Create a new tag
	git tag v$(NEW_VERSION)

	# Push the tag to the remote repository
	git push origin v$(NEW_VERSION)
