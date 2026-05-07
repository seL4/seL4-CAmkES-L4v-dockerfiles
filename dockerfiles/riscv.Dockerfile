#
# Copyright 2026, Proofcraft Pty Ltd
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

ARG BASE_IMG=trustworthysystems/base_tools
# hadolint ignore=DL3006
FROM $BASE_IMG

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Gerwin Klein <gerwin.klein@proofcraft.systems>"
LABEL PREBUILT="yes"

# Get source for RISCV compilers, and build them
# Prerequisites from https://github.com/riscv-collab/riscv-gnu-toolchain

# hadolint ignore=DL3008
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        autoconf automake autotools-dev curl python3 python3-pip python3-tomli \
        libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex \
        texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build \
        git cmake libglib2.0-dev libslirp-dev libncurses-dev \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/apt/lists/*

ENV RISCV=/opt/riscv

RUN git clone https://github.com/riscv/riscv-gnu-toolchain.git

WORKDIR /riscv-gnu-toolchain

# Use the latest release tag (YYYY.MM.DD) to ensure a known-good version
RUN LATEST_TAG=$(git tag -l '????.??.??' | sort -V | tail -n 1) \
    && echo "Building riscv-gnu-toolchain at tag: $LATEST_TAG" \
    && git checkout "$LATEST_TAG"

RUN ./configure --prefix=$RISCV && make -j"$(nproc)"
