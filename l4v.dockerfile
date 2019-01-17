ARG BASE_IMG=trustworthysystems/camkes
FROM $BASE_IMG
LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

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
    && ln -s /isabelle ~/.isabelle \
    && mkdir -p ~/.isabelle/etc

COPY res/isabelle_settings /root/.isabelle/etc/settings

# Get a copy of the L4v repo, and build all the isabelle and haskell 
# components, essentially caching them in the image.
RUN mkdir /root/verification \
    && cd /root/verification \
    && /scripts/repo/repo init -u ${SCM}/seL4/verification-manifest.git \
    && /scripts/repo/repo sync -c \
    && cd /root/verification/l4v \
    && ./isabelle/bin/isabelle components -a \
    && cd /root/verification/l4v/spec/haskell \
    && make sandbox \
    && cd \
    && rm -rf /root/verification \
    && rm -rf /tmp/isabelle-
