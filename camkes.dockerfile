ARG BASE_IMG=trustworthysystems/sel4
FROM $BASE_IMG
LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

# Get dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update -q \
    && apt-get install -y --no-install-recommends \
        fakeroot \
        lib32stdc++-6-dev \
        linux-libc-dev-i386-cross \
        linux-libc-dev:i386 \
        # Required for testing
        gdb \
        libssl-dev \
        libcunit1-dev \
        libglib2.0-dev \
        libsqlite3-dev \
        libgmp3-dev \
        # Required for stack to use tcp properly
        netbase \
        pkg-config \
        spin \
        # Required for rumprun
        dh-autoreconf \
        genisoimage \
        gettext \
        rsync \
        xxd \
        # Required for cakeml
        polyml \
        libpolyml-dev \
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
ENV PATH "$PATH:$HOME/.local/bin"

# CAmkES is hard coded to look for clang in /opt/clang/
RUN ln -s /usr/lib/llvm-3.8 /opt/clang

# Get a repo that relys on stack, and use it to init the stack cache \
# then delete the repo, because we don't need it.
RUN git clone https://github.com/seL4/capdl.git \
    && cd capdl/capDL-tool \
    && stack setup \
    && stack build --only-dependencies \
    && cd / \
    && rm -rf capdl
