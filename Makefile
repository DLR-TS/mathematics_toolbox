SHELL:=/bin/bash

.DEFAULT_GOAL := help 

ROOT_DIR:=$(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")

.EXPORT_ALL_VARIABLES:
DOCKER_BUILDKIT?=1
DOCKER_CONFIG?=
ARCH?=$(shell uname -m)
DOCKER_PLATFORM?=linux/$(ARCH)
CROSS_COMPILE?=$(shell if [ "$(shell uname -m)" != "$(ARCH)" ]; then echo "true"; else echo "false"; fi)

OSQP_PROJECT=osqp
OSQP_TAG=latest_${ARCH}
OSQP_IMAGE=${OSQP_PROJECT}:${OSQP_TAG}

EIGEN_PROJECT=eigen3
EIGEN_TAG=latest_${ARCH}
EIGEN_IMAGE=${EIGEN_PROJECT}:${EIGEN_TAG}

DOCKER_REPOSITORY="andrewkoerner/adore"
DOCKER_CACHE_DIRECTORY="${ROOT_DIR}/.docker_cache"
DOCKER_ARCHIVE="${DOCKER_CACHE_DIRECTORY}/mathematics_toolbox.tar"





.PHONY: help
help:
	@printf "Usage: make \033[36m<target>\033[0m\n%s\n" "$$(awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST) | sort | uniq)"


.PHONY: check_cross_compile_deps
check_cross_compile_deps:
	@if [ "$(CROSS_COMPILE)" = "true" ]; then \
        echo "Cross-compiling for $(ARCH) on $(shell uname -m)"; \
        if ! which qemu-$(ARCH)-static >/dev/null || ! docker buildx inspect $(ARCH)builder >/dev/null 2>&1; then \
            echo "Installing cross-compilation dependencies..."; \
            sudo apt-get update && sudo apt-get install -y qemu qemu-user-static binfmt-support; \
            docker run --privileged --rm tonistiigi/binfmt --install $(ARCH); \
            if ! docker buildx inspect $(ARCH)builder >/dev/null 2>&1; then \
                docker buildx create --name $(ARCH)builder --driver docker-container --use; \
            fi; \
        fi; \
    fi

.PHONY: build
build: all ## 1) Loads the docker images from the DOCKER_ARCHIVE directory, 2) Fetches the docker images from docker.io, 3) Builds from scratch if neither are available.  Invoke `make clean_build` to trigger a build. 

.PHONY: init_submodules
init_submodules:
ifeq ($(wildcard eigen3/*),)
	@echo "ERROR: submodules not initialized, call 'git submodule update --init' and try again." >&2 && exit 1
else
	@echo "Submodules already initialized, skipping submodule init."
endif

.PHONY: save_docker_images
save_docker_images:
	mkdir -p "${DOCKER_CACHE_DIRECTORY}"
	@if [ -w "$$(dirname "${DOCKER_ARCHIVE}")" ]; then \
        rm -rf "${DOCKER_ARCHIVE}"; \
        echo "Saving Docker images to ${DOCKER_ARCHIVE}..."; \
        docker save -o "${DOCKER_ARCHIVE}" ${OSQP_IMAGE} ${EIGEN_IMAGE}; \
    else \
        echo "WARNING: Directory $$(dirname "${DOCKER_ARCHIVE}") is not writable. Unable to save docker images, skipping saving of docker images."; \
    fi

.PHONY: load_docker_images
load_docker_images:
	@docker load --input "${DOCKER_ARCHIVE}" 2>/dev/null || true

.PHONY: build_osqp
build_osqp: init_submodules set_osqp_env _build
set_osqp_env: 
	$(eval PROJECT := ${OSQP_PROJECT}) 
	$(eval TAG := ${OSQP_TAG})
.PHONY: build_fast_osqp
build_fast_osqp: set_osqp_env
	@if [ -n "$$(docker images -q ${PROJECT}:${TAG})" ]; then \
        echo "Docker image: ${PROJECT}:${TAG} already build, skipping build."; \
    else \
        make build_osqp;\
    fi
	docker cp $$(docker create --rm ${PROJECT}:${TAG}):/tmp/${PROJECT}/build ${PROJECT}

.PHONY: build_eigen3
build_eigen3: init_submodules set_eigen3_env _build
set_eigen3_env: 
	$(eval PROJECT := ${EIGEN_PROJECT}) 
	$(eval TAG := ${EIGEN_TAG})
.PHONY: build_fast_eigen3
build_fast_eigen3: set_eigen3_env
	@if [ -n "$$(docker images -q ${PROJECT}:${TAG})" ]; then \
        echo "Docker image: ${PROJECT}:${TAG} already build, skipping build."; \
    else \
        make build_eigen3;\
    fi
	docker cp $$(docker create --rm ${PROJECT}:${TAG}):/tmp/${PROJECT}/build ${PROJECT}

.PHONY: all
all:
	make load_docker_images
	make docker_pull_fast
	make build_fast_osqp
	make build_fast_eigen3
	make save_docker_images

.PHONY: clean_build 
clean_build: clean ## Build all dependencies from scratch
	git submodule update --init --recursive
	rm -rf ${DOCKER_CACHE_DIRECTORY}
	make build_osqp
	make build_eigen3

.PHONY: _build
_build: check_cross_compile_deps
	rm -rf ${PROJECT}/build
	@if [ "$(CROSS_COMPILE)" = "true" ]; then \
        echo "Cross-compiling ${PROJECT}:${TAG} for $(ARCH)..."; \
        docker buildx build --platform $(DOCKER_PLATFORM) \
                --tag ${PROJECT}:${TAG} \
                --build-arg PROJECT=${PROJECT} \
                --load .; \
    else \
        docker build --network host \
                --tag ${PROJECT}:${TAG} \
                --build-arg PROJECT=${PROJECT} .; \
    fi
	docker cp $$(docker create --rm ${PROJECT}:${TAG}):/tmp/${PROJECT}/build ${PROJECT}

.PHONY: test
test:
	cd tests && make test_osqp && make test_eigen3

.PHONY: clean
clean: ## Clean build artifacts and docker images
	cd "${ROOT_DIR}" && rm -rf $$(find . -name build -type d)
	docker rm $$(docker ps -a -q --filter "ancestor=${OSQP_IMAGE}") 2> /dev/null || true
	docker rmi $$(docker images -q ${OSQP_IMAGE}) 2> /dev/null || true
	docker rm $$(docker ps -a -q --filter "ancestor=${OSQP_IMAGE}") 2> /dev/null || true
	
	docker rm $$(docker ps -a -q --filter "ancestor=${EIGEN_IMAGE}") 2> /dev/null || true
	docker rmi $$(docker images -q ${EIGEN_IMAGE}) 2> /dev/null || true
	docker rm $$(docker ps -a -q --filter "ancestor=${EIGEN_IMAGE}") 2> /dev/null || true

.PHONY: publish
publish: docker_publish ## Publish all docker images built by this project to docker hub. Must be logged in

.PHONY: docker_publish
docker_publish: save_docker_images
	docker tag "${OSQP_TAG}" "${DOCKER_REPOSITORY}:${OSQP_PROJECT}_${OSQP_VERSION}"
	docker push "${DOCKER_REPOSITORY}:${OSQP_PROJECT}_${OSQP_VERSION}"
	
	docker tag "${EIGEN_TAG}" "${DOCKER_REPOSITORY}:${EIGEN_PROJECT}_${EIGEN_VERSION}"
	docker push "${DOCKER_REPOSITORY}:${EIGEN_PROJECT}_${EIGEN_VERSION}"
	
.PHONY: docker_pull
docker_pull:
	docker pull "${DOCKER_REPOSITORY}:${OSQP_PROJECT}_${OSQP_TAG}" || true
	docker tag "${DOCKER_REPOSITORY}:${OSQP_PROJECT}_${OSQP_TAG}" "${OSQP_IMAGE}" || true
	docker rmi "${DOCKER_REPOSITORY}:${OSQP_PROJECT}_${OSQP_TAG}" || true
	
	docker pull "${DOCKER_REPOSITORY}:${EIGEN_PROJECT}_${EIGEN_TAG}" || true
	docker tag "${DOCKER_REPOSITORY}:${EIGEN_PROJECT}_${EIGEN_TAG}" "${EIGEN_IMAGE}" || true
	docker rmi "${DOCKER_REPOSITORY}:${EIGEN_PROJECT}_${EIGEN_TAG}" || true

.PHONY: docker_pull_fast
docker_pull_fast:
	@[ -n "$$(docker images -q ${EIGEN_IMAGE})" ] || make docker_pull
	@[ -n "$$(docker images -q ${EIGEN_IMAGE})" ] || make docker_pull

