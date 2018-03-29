FROM ubuntu:16.04

RUN apt-get update -q \
    && apt-get install -y --allow-downgrades --no-install-recommends \
        # General packages:
        git repo python-dev \
        # For RISC-V tools:
        autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev device-tree-compiler pkg-config \
        # For RISC-V QEMU:
        libglib2.0-dev zlib1g-dev libpixman-1-dev  \
        # For seL4:
        build-essential realpath libxml2-utils python-pip gcc-multilib ccache ncurses-dev cpio \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ \
    && pip install --upgrade pip \
    && pip install setuptools \
    && pip install sel4-deps


RUN curl -k -sL https://bitbucket.keg.ertos.in.nicta.com.au/users/mon13k/repos/sel4-riscv/raw/bamboo_sel4riscv.sh -o bamboo_sel4riscv.sh \
    && export RISCV=/opt/riscv \
    && bash -x ./bamboo_sel4riscv.sh \
    && rm -rf /riscv-tools

ENV RISCV /opt/riscv/bin
ENV PATH "$PATH:$RISCV"
