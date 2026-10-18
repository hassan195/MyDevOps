SHELL := /bin/bash
-include .env
DOCKER_IMAGE_NAME ?= week5-2-app
TAG ?= local
export DOCKER_IMAGE_NAME
export TAG
.DEFAULT_GOAL := help
.PHONY: lint build run push help

help:
	@echo "Usage: make [target]"
	@echo "Available targets:"
	@echo "make  lint   - Lint the Dockerfile"
	@echo "make  build  - Build the Docker image"
	@echo "make  run    - Run the Docker container"
	@echo "make  push   - Push the Docker image to the registry"

lint:
	@echo "Linting the Dockerfile..."
	docker run --rm -i hadolint/hadolint < Dockerfile || true
build: lint	
	@echo "Building the Docker image..."
	docker build -t $(DOCKER_IMAGE_NAME):$(TAG) .
run:
	@echo "Running the Docker container..."
	docker compose up -d --wait --wait-timeout 60
push:
	@echo "Pushing the Docker image to the registry..."
	docker push $(DOCKER_IMAGE_NAME):$(TAG)