# Docker image for running Bamboo Server
FROM debian:jessie

# Fetch some basics
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
    	curl \
	gettext \
        git \
    	make \
        wget


# Get repo
RUN mkdir -p /scripts \
    && cd /scripts \
    && git clone -b seL4 http://bitbucket.keg.ertos.in.nicta.com.au/scm/sel4/repo.git \
    && echo 'export PATH=$PATH:/scripts/repo' >> /root/.bashrc


# Cleanup
RUN apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/


