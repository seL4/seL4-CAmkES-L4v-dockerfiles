#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

ARG BASE_IMG=debian:trixie-slim
# hadolint ignore=DL3006
FROM $BASE_IMG
ARG TARGETPLATFORM
LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

# ARGS are env vars that are *only available* during the docker build
# They can be modified at docker build time via '--build-arg VAR="something"'
ARG SCM
ARG DESKTOP_MACHINE=no
ARG USE_DEBIAN_SNAPSHOT
ARG SNAPSHOT_DATE
ARG MAKE_CACHES=yes

ARG SCRIPTS_DIR="/scripts"
ARG REPO_DIR="${SCRIPTS_DIR}/repo"

ARG SCRIPT=base_tools.sh

COPY scripts /tmp/

# ip4v forces curl to use ipv4. Weirdness happens with docker and ipv6.
RUN echo ipv4 >> ~/.curlrc \
    && /bin/bash "/tmp/${SCRIPT}" \
    && apt-get clean autoclean \
    && apt-get autoremove --purge --yes \
    && rm -rf /var/lib/apt/lists/*

# ENV variables are available to containers after the build stage
ENV PATH="${PATH}:${REPO_DIR}"
