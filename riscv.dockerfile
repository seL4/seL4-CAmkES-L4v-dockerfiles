ARG BASE_IMG=trustworthysystems/sel4
FROM $BASE_IMG

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

# Get source for RISCV compilers, and build them

RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        # For RISC-V tools:
        autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev device-tree-compiler pkg-config \
        # For RISC-V QEMU:
        libglib2.0-dev zlib1g-dev libpixman-1-dev  \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ 

ENV RISCV /opt/riscv
ENV PATH "$PATH:$RISCV"

RUN git clone https://github.com/riscv/riscv-tools.git 

WORKDIR /riscv-tools

RUN git submodule update --init --recursive

RUN git clone https://github.com/heshamelmatary/riscv-qemu.git \
    && cd riscv-qemu \
    && git checkout sfence \
    && git submodule update --init dtc

RUN cd riscv-qemu \
    && ./configure --target-list=riscv64-softmmu,riscv32-softmmu --prefix=$RISCV \
    && make -j 8 \
    && make install

# Setup riscv-tools/gnu-riscv to build "soft-float" toolchain
RUN sed -i 's/build_project riscv-gnu-toolchain --prefix=$RISCV/build_project riscv-gnu-toolchain --prefix=$RISCV --with-arch=rv64imafdc --with-abi=lp64 --enable-multilib/g' ./build.sh

## 64-bit
RUN ./build.sh 

## 32-bit 
RUN ./build-rv32ima.sh
