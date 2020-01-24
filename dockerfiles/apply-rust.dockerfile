ARG BASE_IMG=trustworthysystems/camkes
FROM $BASE_IMG

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

# ARGS are env vars that are *only available* during the docker build
# They can be modified at docker build time via '--build-arg VAR="something"'
ARG SCM=https://bitbucket.ts.data61.csiro.au/scm
ARG DESKTOP_MACHINE=no
ARG INTERNAL=yes
ARG MAKE_CACHES=yes

ARG SCRIPT=apply-rust.sh

COPY scripts /tmp/

RUN /bin/bash /tmp/${SCRIPT} \
    && apt-get clean autoclean \
    && apt-get autoremove --purge --yes \
    && rm -rf /var/lib/apt/lists/*

# Docker doesn't know the HOME variable at this level, so we have to set it by
# hand here. I don't like it, but it works for now. We currently build as `root`
# so this should work fine.
ARG HOME="/root"
# Doubley make sure that the PATH is set right
ENV PATH "${PATH}:${HOME}/.cargo/bin"
