# Additional dependencies required to build CAmkES
ARG BASE_IMG=trustworthysystems/sel4
FROM $BASE_IMG
MAINTAINER Luke Mondy (luke.mondy@data61.csiro.au)

# Get dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update -q \
    && apt-get install -y --no-install-recommends \
        clang \
        device-tree-compiler \
        fakeroot \
        lib32stdc++-6-dev \
        linux-libc-dev-i386-cross \
        linux-libc-dev:i386 \
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
        dh-autoreconf \
        gettext \
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

# Set up tools to compile CakeML
RUN git clone https://github.com/HOL-Theorem-Prover/HOL.git \
    && cd HOL \
    && git checkout 7323105f50960bdec1b33c513576e5d1d313b62f \
    && mkdir -p tools-poly \
    && echo "val polymllibdir = \"/usr/lib/x86_64-linux-gnu/\";" > tools-poly/poly-includes.ML \
    && poly < tools/smart-configure.sml \
    && bin/build \
    && chmod -R 757 /HOL

ENV PATH "$PATH:$HOME/HOL/bin"

RUN wget https://cakeml.org/regression/artefacts/473/cake-x64-32.tar.gz \
    && tar -xvzf cake-x64-32.tar.gz \
    && cd cake-x64-32 \
    && make cake \
    && rm /cake-x64-32.tar.gz

RUN wget https://cakeml.org/regression/artefacts/473/cake-x64-64.tar.gz \
    && tar -xvzf cake-x64-64.tar.gz \
    && cd cake-x64-64 \
    && make cake \
    && rm /cake-x64-64.tar.gz

RUN git clone https://github.com/CakeML/cakeml.git \
    && cd cakeml \
    && git checkout 66a35311787bb43f72e8e758209a4745f288cdfe \
    # Pre-build the following cakeml directories to speed up subsequent cakeml app builds
    && for dir in "characteristic" "basis" "misc" "translator" "semantics" "unverified/sexpr-bootstrap" \
    "compiler/parsing" "semantics/proofs"; \
        do \
            cd /cakeml/${dir} && /HOL/bin/Holmake; \
        done \
    && chmod -R 757 /cakeml
