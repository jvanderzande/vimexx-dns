# Detecteer of 'docker ps' werkt zonder sudo; anders gebruik 'sudo docker'
DOCKER := $(shell if docker ps > /dev/null 2>&1; then echo docker; else echo sudo docker; fi)

# Directory waar Dockerfiles staan
DOCKER_DIR := docker

# Vind alle Dockerfile.* bestanden
DOCKERFILES := $(wildcard $(DOCKER_DIR)/Dockerfile.*)

# Haal de image-namen eruit (bijv. Dockerfile.app → app)
IMAGES := $(patsubst $(DOCKER_DIR)/Dockerfile.%,%, $(DOCKERFILES))

# Basisnaam van de image zonder tag
IMAGE_PREFIX := 2kman/vimexx-ddns-client

# Versie die aan images wordt toegevoegd
VERSION := 1.2.0

# Default target
.PHONY: all
all: build

# Build alle images
.PHONY: build
build: $(IMAGES:%=build-%)

# Tag alle images (optioneel; tagging gebeurt al tijdens build)
.PHONY: tag
tag: $(IMAGES:%=tag-%)

# Push alle images
.PHONY: push
push: $(IMAGES:%=push-%)

# Clean images
.PHONY: clean
clean:
	@for image in $(IMAGES); do \
		if $(DOCKER) image inspect $(IMAGE_PREFIX):$$image > /dev/null 2>&1; then \
			echo "Removing image: $(IMAGE_PREFIX):$$image"; \
			$(DOCKER) rmi -f $(IMAGE_PREFIX):$$image; \
		else \
			echo "Image $(IMAGE_PREFIX):$$image does not exist. Skipping."; \
		fi; \
		if $(DOCKER) image inspect $(IMAGE_PREFIX):$$image-$(VERSION) > /dev/null 2>&1; then \
			echo "Removing image: $(IMAGE_PREFIX):$$image-$(VERSION)"; \
			$(DOCKER) rmi -f $(IMAGE_PREFIX):$$image-$(VERSION); \
		else \
			echo "Image $(IMAGE_PREFIX):$$image-$(VERSION) does not exist. Skipping."; \
		fi; \
	done

# Targets voor individuele images
build-%:
	$(DOCKER) build -f $(DOCKER_DIR)/Dockerfile.$* \
		-t $(IMAGE_PREFIX):$* \
		-t $(IMAGE_PREFIX):$*-$(VERSION) .

tag-%:
	@echo "Images are already tagged with :$* and :$*-$(VERSION) during build"

push-%:
	$(DOCKER) push $(IMAGE_PREFIX):$*
	$(DOCKER) push $(IMAGE_PREFIX):$*-$(VERSION)

# Alles in één keer voor een specifieke image
.PHONY: all-%
all-%: build-% push-%

# Start een container met environment config
.PHONY: start-%
start-%:
	@if [ ! -f docker/env ]; then \
		echo "❌ Error: 'env' file not found. Cannot start container."; \
		exit 1; \
	fi
	@if [ ! -f conf ]; then \
		echo "❌ Error: 'conf' file not found. Cannot start container."; \
		exit 1; \
	fi
	$(DOCKER) run -d --rm -v $(CURDIR)/conf:/etc/vimexx-dns.conf:ro --env-file docker/env --name $* $(IMAGE_PREFIX):$*-$(VERSION)

# Stop een container
.PHONY: stop-%
stop-%:
	$(DOCKER) stop $* || true

# Start of stop alle containers
.PHONY: start stop
start: $(IMAGES:%=start-%)
stop:  $(IMAGES:%=stop-%)

