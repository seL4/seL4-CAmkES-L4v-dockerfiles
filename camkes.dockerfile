# Docker image for running Bamboo Server
FROM selfour


# Get dependencies
RUN apt-get install -y --no-install-recommends \
        cmake \
        clang \
        libssl-dev \
        libcunit1-dev \
        libsqlite3-dev \
        locales \
        libgmp3-dev \
        ninja-build 


# Setup correct version of GHC
RUN cd /root \
    && wget http://www.haskell.org/ghc/dist/7.8.1/ghc-7.8.1-x86_64-unknown-linux-deb7.tar.bz2 \
    && tar -xf ghc-7.8.1-x86_64-unknown-linux-deb7.tar.bz2 \
    && rm /root/ghc-7.8.1-x86_64-unknown-linux-deb7.tar.bz2

RUN cd /root/ghc-7.8.1 \
    && ./configure --prefix=/usr/local \
    && make install

RUN rm -rf /root/ghc-7.8.1


# Get Cabal
RUN cd /root \
    && wget http://hackage.haskell.org/package/cabal-install-1.22.7.0/cabal-install-1.22.7.0.tar.gz \
    && tar -xvf cabal-install-1.22.7.0.tar.gz

RUN cd /root/cabal-install-1.22.7.0 \
    && ./bootstrap.sh 

RUN ln -s /root/.cabal/bin/cabal /usr/local/bin/cabal

RUN cabal update --verbose \
    && cabal install data-ordlist \
    && cabal install cabal-install --global


# Get python packages for CAmkES
RUN apt-get install -y --no-install-recommends \
        python-jinja2 \
        python-ply

RUN pip install --upgrade pip \
    && pip install --allow-all-external \
        pyelftools


# Set up locales (needed by camkes-next)
RUN echo 'en_AU.UTF-8 UTF-8' > /etc/locale.gen
RUN dpkg-reconfigure --frontend=noninteractive locales

