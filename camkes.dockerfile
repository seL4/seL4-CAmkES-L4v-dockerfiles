# Docker image for running Bamboo Server
FROM selfour_gcc5

# Get dependencies
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        cmake \
        clang \
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
        ninja-build \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Get orderedset for CAmkES VM
RUN pip install --allow-all-external \
        orderedset

# Setup correct version of GHC
RUN cd /root \
    && wget --quiet http://www.haskell.org/ghc/dist/7.8.1/ghc-7.8.1-x86_64-unknown-linux-deb7.tar.bz2 \
    && tar -xf ghc-7.8.1-x86_64-unknown-linux-deb7.tar.bz2 \
    && rm /root/ghc-7.8.1-x86_64-unknown-linux-deb7.tar.bz2 \
    && cd /root/ghc-7.8.1 \
    && ./configure --prefix=/usr/local \
    && make install \
    && rm -rf /root/ghc-7.8.1

# Get Cabal
RUN cd /root \
    && wget --quiet http://hackage.haskell.org/package/cabal-install-1.22.7.0/cabal-install-1.22.7.0.tar.gz \
    && tar -xvf cabal-install-1.22.7.0.tar.gz \
    && rm cabal-install-1.22.7.0.tar.gz \
    && cd /root/cabal-install-1.22.7.0 \
    && ./bootstrap.sh \
    && ln -s /root/.cabal/bin/cabal /usr/local/bin/cabal

# Get cabal CAmkES dependencies
RUN cabal update --verbose \
    && cabal install cabal-install --global \
    && cabal install \
        base-compat-0.9.0 \
        data-ordlist \
        missingh-1.3.0.1 \
        split

# CAmkES is hard coded to look for clang in /opt/clang/
RUN ln -s /usr/lib/llvm-3.8 /opt/clang

# Set up locales (needed by camkes-next)
RUN echo 'en_AU.UTF-8 UTF-8' > /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && echo "LANG=en_AU.UTF-8" >> /etc/default/locale 

ENV LANG en_AU.UTF-8
