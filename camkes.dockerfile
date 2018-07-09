# Additional dependencies required to build CAmkES
ARG BASE_IMG=trustworthysystems/sel4
FROM $BASE_IMG
MAINTAINER Luke Mondy (luke.mondy@data61.csiro.au)

# Get dependencies
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        clang \
        device-tree-compiler \
        # Required for testing
        gdb \
        libssl-dev \
        libclang-dev \
        libcunit1-dev \
        libglib2.0-dev \
        libsqlite3-dev \
        libgmp3-dev \
        # Required for stack to use tcp properly
        netbase \
        pkg-config \
        spin \
        # Required for rumprun
        rsync \
        xxd \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Get python deps for CAmkES
RUN for p in "pip2" "pip3"; \
    do \
        ${p} install --no-cache-dir \
            camkes-deps \
            jinja2; \
    done

# Get stack
RUN wget -O - https://get.haskellstack.org/ | sh

# CAmkES is hard coded to look for clang in /opt/clang/
RUN ln -s /usr/lib/llvm-3.8 /opt/clang

# Get a repo that relys on stack, and use it to init the stack cache \
# then delete the repo, because we don't need it.
RUN git clone https://github.com/seL4/capdl.git \
    && cd capdl/capDL-tool \
    && stack setup \
    && stack build --only-dependencies \
    && cd / \
    && rm -rf capdl.git
