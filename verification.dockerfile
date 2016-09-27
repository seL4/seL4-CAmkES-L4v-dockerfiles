FROM jdk

# Get isabelle
RUN perl -MCPAN -e'install "LWP::Simple"' \
    && mkdir /root/verification \
    && cd /root/verification \
    && /scripts/repo/repo init -u ssh://git@bitbucket.keg.ertos.in.nicta.com.au:7999/sel4/verification-manifest.git \
    && /scripts/repo/repo sync \
    && cd l4v \
    && mkdir -p ~/.isabelle/etc \
    && cp -i misc/etc/settings ~/.isabelle/etc/settings \
    && ./isabelle/bin/isabelle components -a \
    && ./isabelle/bin/isabelle jedit -bf \
    && ./isabelle/bin/isabelle build -bv HOL-Word


# Setup mail
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        exim4 \
        mailutils \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/
 
COPY res/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf
RUN update-exim4.conf && service exim4 restart


# Get addditional deps for verification related regressions
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        bzip2 \
        librsvg2-bin \
        python3-pip \
        texlive-bibtex-extra \
        texlive-generic-extra \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN python3 -m pip install \
        lxml \
        psutil


# CakeML
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        bsdutils \
        time \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/
