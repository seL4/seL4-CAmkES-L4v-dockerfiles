# Docker image for running Bamboo Server
FROM debian:stretch

# Fetch some basics
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        make \
        python-pip \
        wget \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/



