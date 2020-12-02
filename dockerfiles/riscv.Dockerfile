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
LABEL PREBUILT="yes"

# Get source for RISCV compilers, and build them

# hadolint ignore=DL3008
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        # For RISC-V tools:
        autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev pkg-config \
        # For RISC-V QEMU:
        libglib2.0-dev zlib1g-dev libpixman-1-dev  \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/apt/lists/*

ENV RISCV /opt/riscv
ENV PATH "$PATH:$RISCV"

RUN git clone https://github.com/riscv/riscv-gnu-toolchain.git

WORKDIR /riscv-gnu-toolchain

RUN git submodule update --init --recursive

# hadolint ignore=DL3003
RUN cd qemu \
    && git checkout master

# Setup qemu targets
RUN sed -i 's/--target-list=riscv64-linux-user,riscv32-linux-user/--target-list=riscv64-softmmu,riscv32-softmmu/g' ./Makefile.in

RUN ./configure --prefix=$RISCV --enable-multilib \
    && make linux \
    && make build-qemu

