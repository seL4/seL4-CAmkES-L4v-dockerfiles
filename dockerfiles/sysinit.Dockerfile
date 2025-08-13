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
LABEL PREBUILT="yes"

# ARGS are env vars that are *only available* during the docker build
# They can be modified at docker build time via '--build-arg VAR="something"'
ARG SCM
ARG DESKTOP_MACHINE=no
ARG MAKE_CACHES=yes

ARG HOL_DIR="/HOL"
ARG CAKEML_DIR="/cakeml"
ARG CAKEML32_BIN_DIR="/cake-x64-32"
ARG CAKEML64_BIN_DIR="/cake-x64-64"
ARG CAKEML_BUILD_NUMBER=393
ARG HOL_COMMIT=d957bf561f9b80133ee4e51cf739610cb249c06a
ARG CAKEML_COMMIT=82033e1e51624f3181ebddb4eadbc30a4a2fef58
ARG CAKEML_REMOTE=https://bitbucket.ts.data61.csiro.au/scm/~spr074/cakeml.git

ARG SCRIPT=cakeml.sh

COPY scripts /tmp/

RUN /bin/bash /tmp/${SCRIPT} \
    && apt-get clean autoclean \
    && apt-get autoremove --purge --yes \
    && rm -rf /var/lib/apt/lists/*

# Doubley make sure that the PATH is set right
ENV PATH="${PATH}:${HOL_DIR}/bin"
