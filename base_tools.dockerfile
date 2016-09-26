# Docker image for running Bamboo Server
FROM debian:stretch

# Fetch some basics
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        bc \
        ca-certificates \
        curl \
        gettext \
        git \
        make \
        moreutils \
        resolvconf \
        wget

# Setup nameservers properly
RUN echo "nameserver 10.13.0.130" > /tmp/out.txt \
    && cat /etc/resolvconf/resolv.conf.d/original >> /tmp/out.txt \
    && mv /tmp/out /etc/resolvconf/resolv.conf.d/original \
    && rm /tmp/out \
    && service resolvconf restart

# Get repo
RUN mkdir -p /scripts \
    && cd /scripts \
    && git clone -b seL4 http://bitbucket.keg.ertos.in.nicta.com.au/scm/sel4/repo.git \
    && echo 'export PATH=$PATH:/scripts/repo' >> /root/.bashrc


# Cleanup
RUN apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/
