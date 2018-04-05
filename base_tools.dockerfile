# Basic dependencies required for seL4
ARG BASE_IMG=debian:stretch
FROM $BASE_IMG
MAINTAINER Luke Mondy (luke.mondy@data61.csiro.au)

# Fetch some basics
RUN sed -i 's/deb.debian.org/httpredir.debian.org/g' /etc/apt/sources.list \
    && apt-get update -q \
    && apt-get install -y --no-install-recommends \
        bc \
        ca-certificates \
        cpio \
        curl \
        git \
        jq \
        make \
        mercurial \
        python-dev \
        python-pip \
        python3-dev \
        python3-pip \
        wget \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/


# Setup python dep manager
RUN for p in "pip2" "pip3"; \
    do \ 
        ${p} install \
            setuptools \
        && ${p} install pip --upgrade \
        && ${p} install \
            pexpect \
            sh; \
    done

# Add nice symlinks
RUN ln -s /usr/bin/hg /usr/local/bin/hg \
    && ln -s /usr/bin/make /usr/bin/gmake

# Get simulators
COPY res/ertos /opt/ertos
#RUN cd /opt/ertos/simulators-x86_64 \
    #&& ln -s /opt/ertos/simulators-x86_64/qemu /usr/bin/qemu 

# Install Google's repo
RUN mkdir -p /scripts/repo \
    && curl https://storage.googleapis.com/git-repo-downloads/repo > /scripts/repo/repo \
    && chmod a+x /scripts/repo/repo

ARG INTERNAL=no
RUN if [ "$INTERNAL" = "yes" ]; then \
        cd /scripts \
        && git clone http://bitbucket.keg.ertos.in.nicta.com.au/scm/sel4proj/console_reboot.git \
        && chmod +x /scripts/console_reboot/simulate/* \
        # Get some useful SEL4 tools
        && git clone http://bitbucket.keg.ertos.in.nicta.com.au/scm/sel4/sel4_libs.git; \
    fi
