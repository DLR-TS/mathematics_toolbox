SHELL:=/bin/bash

.DEFAULT_GOAL := all

ROOT_DIR:=$(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")

MAKEFLAGS += --no-print-directory

.EXPORT_ALL_VARIABLES:
DOCKER_BUILDKIT?=1
DOCKER_CONFIG?=


.PHONY: help
help:
	@printf "Usage: make \033[36m<target>\033[0m\n%s\n" "$$(awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST) | sort | uniq)"

.PHONY: test_osqp
test_osqp: ##Run test of osqp library implementation
	cd osqp_hello_world && docker build -t osqp_hello_world:latest -f Dockerfile.osqp_hello_world .
	docker run -it osqp_hello_world:latest /tmp/osqp_hello_world/build/osqp_hello_world

.PHONY: test_eigen3
test_eigen3: ##Run test of eigen library implementation
	cd eigen3_hello_world && docker build -t eigen3_hello_world:latest -f Dockerfile.eigen3_hello_world .
	docker run -it eigen3_hello_world:latest /tmp/eigen3_hello_world/build/eigen3_hello_world
