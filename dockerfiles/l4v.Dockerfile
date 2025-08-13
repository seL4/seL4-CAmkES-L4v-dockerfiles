#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

ARG BASE_IMG=trustworthysystems/camkes
# hadolint ignore=DL3006
FROM $BASE_IMG
ARG TARGETPLATFORM
LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

##########################################################
# Do some setup to prepare for the shell script to be run
COPY res/isabelle_settings /tmp
ENV NEW_ISABELLE_SETTINGS="/tmp/isabelle_settings"
##########################################################

# ARGS are env vars that are *only available* during the docker build
# They can be modified at docker build time via '--build-arg VAR="something"'
ARG SCM
ARG DESKTOP_MACHINE=no
ARG USE_DEBIAN_SNAPSHOT
ARG MAKE_CACHES=yes

COPY scripts /tmp/

RUN /bin/bash /tmp/l4v.sh \
    && apt-get clean autoclean \
    && apt-get autoremove --purge --yes \
    && rm -rf /var/lib/apt/lists/*
