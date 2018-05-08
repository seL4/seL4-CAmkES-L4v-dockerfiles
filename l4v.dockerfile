# Dependencies required to verify seL4
ARG CAMKES_IMG=trustworthysystems/camkes
FROM $CAMKES_IMG
MAINTAINER Luke Mondy (luke.mondy@data61.csiro.au)

ARG SCM=https://github.com

# Get dependencies
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        librsvg2-bin \
        libwww-perl \
        libxslt-dev \
        mlton \
        texlive-bibtex-extra \
        texlive-fonts-recommended \
        texlive-generic-extra \
        texlive-latex-extra \
        texlive-metapost \
        # dependencies for testing
        less \
        python-psutil \
        python-lxml \
        # TESTING packages
        libxml2-dev/testing \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/


# Get l4v and setup isabelle
RUN mkdir /isabelle \
    && mkdir -p ~/.isabelle/etc

COPY res/isabelle_settings /root/.isabelle/etc/settings

RUN mkdir /root/verification \
    && cd /root/verification \
    && /scripts/repo/repo init -u ${SCM}/seL4/verification-manifest.git \
    && /scripts/repo/repo sync -c

RUN cd /root/verification/l4v \
    && ./isabelle/bin/isabelle components -a \
    && ./isabelle/bin/isabelle jedit -bf \
    && ./isabelle/bin/isabelle build -bv HOL-Word \
    && rm -rf /root/verification \
    && rm -rf /tmp/isabelle-


# To perform the Haskell kernel regression, we need cabal
#RUN cd /root \
#    && curl -k -L -o ghc.tar.bz2 http://www.haskell.org/ghc/dist/7.8.1/ghc-7.8.1-x86_64-unknown-linux-deb7.tar.bz2 \
#    && tar -xf ghc.tar.bz2 \
#    && rm /root/ghc.tar.bz2 \
#    && cd /root/ghc-7.8.1 \
#    && ./configure --prefix=/usr/local \
#    && make install \
#    && rm -rf /root/ghc-7.8.1 
#
#RUN cd root \
#    && curl -L -O http://hackage.haskell.org/package/cabal-install-1.22.7.0/cabal-install-1.22.7.0.tar.gz \
#    && tar -xf cabal-install-1.22.7.0.tar.gz \
#    && rm cabal-install-1.22.7.0.tar.gz \
#    && cd /root/cabal-install-1.22.7.0 \
#    && ./bootstrap.sh \
#    && ln -s /root/.cabal/bin/cabal /usr/local/bin/cabal \
#    && cabal update --verbose \
#    && cabal install cabal-install --global 

