IMAGE_NAME=vulkan
TAG=reproducable
CONTAINER_NAME=vulkan-repro

.PHONY: all build push start stop attach test run

build: Dockerfile
	docker build . -t babbleshack/${IMAGE_NAME}:${TAG}

push: 
	docker push babbleshack/${IMAGE_NAME}:${TAG}

start: build
	docker run -d --rm --name ${CONTAINER_NAME} babbleshack/${IMAGE_NAME}:${TAG} sleep inf

stop:
	docker kill ${CONTAINER_NAME}

attach:
	docker exec -it ${CONTAINER_NAME} bash

test:
	docker exec -it ${CONTAINER_NAME} vulkaninfo

## Runs a one time container deleted when shell exits
run: build
	docker run -it --rm babbleshack/${IMAGE_NAME}:${TAG} bash

all: build push

default: all
