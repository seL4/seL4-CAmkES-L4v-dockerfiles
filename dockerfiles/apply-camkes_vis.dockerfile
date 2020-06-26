ARG BASE_IMG=trustworthysystems/camkes
FROM $BASE_IMG

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

# ARGS are env vars that are *only available* during the docker build
# They can be modified at docker build time via '--build-arg VAR="something"'
ARG SCM=https://bitbucket.ts.data61.csiro.au/scm
ARG DESKTOP_MACHINE=no
ARG USE_DEBIAN_SNAPSHOT=yes
ARG INTERNAL=yes
ARG MAKE_CACHES=yes

ARG SCRIPT=apply-camkes_vis.sh

COPY scripts /tmp/

RUN /bin/bash /tmp/${SCRIPT} \
    && apt-get clean autoclean \
    && apt-get autoremove --purge --yes \
    && rm -rf /var/lib/apt/lists/*
