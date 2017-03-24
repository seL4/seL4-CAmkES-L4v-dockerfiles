# Additional dependencies required to build CAmkES
FROM sel4
MAINTAINER Luke Mondy (luke.mondy@data61.csiro.au)

# Get dependencies
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        cmake \
        clang \
        device-tree-compiler \
        expect \
        libssl-dev \
        libclang-dev \
        libcunit1-dev \
        libglib2.0-dev \
        libsqlite3-dev \
        locales \
        libgmp3-dev \
        pkg-config \
        python-dev \
        python-jinja2 \
        python-ply \
        python-pyelftools \
        python-setuptools \
        qemu-kvm \
        ninja-build \
        xxd \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Get python deps for CAmkES VM
RUN pip install --allow-all-external \
        orderedset \
        plyplus

# Get stack
RUN curl -sSL https://get.haskellstack.org/ | sh

# CAmkES is hard coded to look for clang in /opt/clang/
RUN ln -s /usr/lib/llvm-3.8 /opt/clang

# Set up locales (needed by camkes-next)
RUN echo 'en_AU.UTF-8 UTF-8' > /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && echo "LANG=en_AU.UTF-8" >> /etc/default/locale 

ENV LANG en_AU.UTF-8
