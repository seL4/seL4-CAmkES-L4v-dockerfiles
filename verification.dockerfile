FROM bamboo-agent-verif 

# Get deps for verification related regressions
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        bzip2 


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
        exim4 
COPY res/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf
RUN service exim4 restart


# CakeML
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        bsdutils \
        time


# Cleanup
RUN apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/


