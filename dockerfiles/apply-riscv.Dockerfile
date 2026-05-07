#
# Copyright 2026, Proofcraft Pty Ltd
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

ARG BASE_BUILDER_IMG=trustworthysystems/riscv
ARG BASE_IMG=trustworthysystems/base_tools

# Load the prebuilt compilers as a throwaway container (named 'builder')
# hadolint ignore=DL3006
FROM $BASE_BUILDER_IMG AS builder

# hadolint ignore=DL3006
FROM $BASE_IMG

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Gerwin Klein <gerwin.klein@proofcraft.systems>"

ENV RISCV=/opt/riscv

COPY --from=builder $RISCV $RISCV

ENV PATH="$RISCV/bin:$PATH"
