#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

ARG BASE_BUILDER_IMG=trustworthysystems/prebuild-cakeml
ARG BASE_IMG=trustworthysystems/sel4

# hadolint ignore=DL3006
FROM $BASE_BUILDER_IMG as builder
# Load the prebuilt compilers as a throwaway container (named 'builder')

# hadolint ignore=DL3006
FROM $BASE_IMG
ARG TARGETPLATFORM

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

ARG HOL_DIR="/HOL"
ARG CAKEML_DIR="/cakeml"
ARG CAKEML32_BIN_DIR="/cake-x64-32"
ARG CAKEML64_BIN_DIR="/cake-x64-64"


COPY --from=builder ${HOL_DIR} ${HOL_DIR}
COPY --from=builder ${CAKEML32_BIN_DIR} ${CAKEML32_BIN_DIR}
COPY --from=builder ${CAKEML64_BIN_DIR} ${CAKEML64_BIN_DIR}
COPY --from=builder ${CAKEML_DIR} ${CAKEML_DIR}

ENV PATH="${PATH}:${HOL_DIR}/bin"
