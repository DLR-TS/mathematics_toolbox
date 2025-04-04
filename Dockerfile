ARG PROJECT

FROM ubuntu:22.04 AS mathematics_toolbox_builder 

ARG PROJECT
ARG REQUIREMENTS_FILE="requirements.${PROJECT}.ubuntu22.04.system"


RUN mkdir -p /tmp/${PROJECT}
COPY files/${REQUIREMENTS_FILE} /tmp/${PROJECT}

WORKDIR /tmp/${PROJECT}

ENV DEBIAN_FRONTEND=noninteractive
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt-get update && \
    apt-get install --no-install-recommends -y checkinstall && \
    apt-get install --no-install-recommends -y apt-transport-https ca-certificates gnupg software-properties-common wget && \
    xargs apt-get install --no-install-recommends -y < ${REQUIREMENTS_FILE} && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null

RUN echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends kitware-archive-keyring && \
    apt-get update && \
    apt-cache madison cmake && \
    apt-cache policy cmake && \
    apt-get install -y --no-install-recommends cmake-data=3.25.1-0kitware1ubuntu22.04.1 cmake=3.25.1-0kitware1ubuntu22.04.1

#RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add - && \
#    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
#    rm -f /usr/share/keyrings/kitware-archive-keyring.gpg && \
#    apt-get update && apt-get install -y --no-install-recommends kitware-archive-keyring && \
#    apt-get update && apt-get install -y --no-install-recommends cmake 


COPY ${PROJECT} /tmp/${PROJECT}/

RUN mkdir -p /tmp/${PROJECT}/build
WORKDIR /tmp/${PROJECT}/build

#RUN cmake -DCMAKE_INSTALL_PREFIX=/usr/local/share/ .. && \
RUN cmake .. && \
    cmake --build . -- -j $(nproc) && \
    cmake --install . && \
    make install && \
    checkinstall -y --pkgname=${PROJECT}

RUN cpack -G DEB && find . -type f -name "*.deb" | xargs mv -t . || true

RUN mv CMakeCache.txt CMakeCache.txt.build

FROM alpine:3.14
FROM debian:stable-slim

ARG PROJECT

COPY --from=mathematics_toolbox_builder /tmp/${PROJECT} /tmp/${PROJECT}

