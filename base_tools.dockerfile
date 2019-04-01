ARG BASE_IMG=debian:buster
FROM $BASE_IMG
LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

# Lines 1-5: Add another mirror for debian to pull packages from.
# Lines 6-8: Do some docker specific tricks with apt.
# Lines under apt-get: get some basic tools.
RUN echo 'deb http://httpredir.debian.org/debian/ buster main' >> /etc/apt/sources.list.d/alternate_mirror.list \
    && echo 'deb http://httpredir.debian.org/debian/ buster-updates main' >> /etc/apt/sources.list.d/alternate_mirror.list \
    && echo 'deb http://mirror.aarnet.edu.au/debian/ buster main' >> /etc/apt/sources.list.d/alternate_mirror.list \
    && echo 'deb http://mirror.aarnet.edu.au/debian/ buster-updates main' >> /etc/apt/sources.list.d/alternate_mirror.list \
    && echo 'deb http://mirror.aarnet.edu.au/debian/ stretch main' >> /etc/apt/sources.list.d/alternate_mirror.list \
    && echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
    && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache \
    && apt-get update -q \
    && apt-get install -y --no-install-recommends \
        bc \
        ca-certificates \
        expect \
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


# Install python dependencies for both python 2 & 3
# Upgrade pip first, then install setuptools (required for other pip packages)
# Install some basic python tools
RUN for p in "pip2" "pip3"; \
    do \ 
        ${p} install --no-cache-dir --upgrade pip==18.1 \
        && ${p} install --no-cache-dir \
            setuptools \
        && ${p} install --no-cache-dir \
            aenum \
            gitlint \
            nose \ 
            pexpect \
            plyplus \
            sh; \
    done

# Add some symlinks so some programs can find things
RUN ln -s /usr/bin/hg /usr/local/bin/hg \
    && ln -s /usr/bin/make /usr/bin/gmake

# Install Google's repo
RUN mkdir -p /scripts/repo \
    && wget -O - https://storage.googleapis.com/git-repo-downloads/repo > /scripts/repo/repo \
    && chmod a+x /scripts/repo/repo
ENV PATH "$PATH:/scripts/repo"

# Get some simulation (QEMU) binaries, and copy them in
COPY res/ertos /opt/ertos

# If this is being built inside Trustworthy Systems, get some scripts used to control simulations
ARG INTERNAL=no
RUN if [ "$INTERNAL" = "yes" ]; then \
        cd /scripts \
        && git clone http://bitbucket.ts.data61.csiro.au/scm/sel4proj/console_reboot.git \
        && chmod +x /scripts/console_reboot/simulate/* \
        # Get some useful SEL4 tools
        && git clone http://bitbucket.ts.data61.csiro.au/scm/sel4/sel4_libs.git; \
    fi
