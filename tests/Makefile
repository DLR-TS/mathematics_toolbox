SHELL:=/bin/bash

.DEFAULT_GOAL := all

ROOT_DIR:=$(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")

MAKEFLAGS += --no-print-directory

.EXPORT_ALL_VARIABLES:
DOCKER_BUILDKIT?=1
DOCKER_CONFIG?=


.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $, $ } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($, 5) } ' $(MAKEFILE_LIST)

.PHONY: test_osqp
test_osqp:
	cd osqp_hello_world && docker build -t osqp_hello_world:latest -f Dockerfile.osqp_hello_world .
	docker run -it osqp_hello_world:latest /tmp/osqp_hello_world/build/osqp_hello_world

.PHONY: test_eigen3
test_eigen3:
	cd eigen3_hello_world && docker build -t eigen3_hello_world:latest -f Dockerfile.eigen3_hello_world . 
	docker run -it eigen3_hello_world:latest /tmp/eigen3_hello_world/build/eigen3_hello_world
