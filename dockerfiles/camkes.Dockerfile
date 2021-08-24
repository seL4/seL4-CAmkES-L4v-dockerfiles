#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

ARG BASE_IMG=trustworthysystems/sel4
# hadolint ignore=DL3006
FROM $BASE_IMG
LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

# ARGS are env vars that are *only available* during the docker build
# They can be modified at docker build time via '--build-arg VAR="something"'
ARG SCM
ARG USE_DEBIAN_SNAPSHOT=yes
ARG DESKTOP_MACHINE=no
ARG MAKE_CACHES=yes
ARG STACK_ROOT=/etc/stack
ARG STACK_GID=1234

ARG SCRIPT=camkes.sh

COPY scripts /tmp/

RUN /bin/bash /tmp/${SCRIPT} \
    && apt-get clean autoclean \
    && apt-get autoremove --purge --yes \
    && rm -rf /var/lib/apt/lists/*
