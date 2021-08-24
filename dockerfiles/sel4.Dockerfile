#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

ARG BASE_IMG=base_tools
# hadolint ignore=DL3006
FROM $BASE_IMG
LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

# ARGS are env vars that are *only available* during the docker build
# They can be modified at docker build time via '--build-arg VAR="something"'
ARG SCM
ARG DESKTOP_MACHINE=no
ARG USE_DEBIAN_SNAPSHOT=yes
ARG MAKE_CACHES=yes

# Use GCC v8 as default? If no, GCC v6 is used
ARG GCC_V8_AS_DEFAULT=yes

ARG SCRIPT=sel4.sh

COPY scripts /tmp/

RUN /bin/bash /tmp/${SCRIPT} \
    && apt-get clean autoclean \
    && apt-get autoremove --purge --yes \
    && rm -rf /var/lib/apt/lists/*

ENV LANG en_AU.UTF-8
