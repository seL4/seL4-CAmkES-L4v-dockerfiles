FROM ssrg_tools_gcc5

# Get deps for verification related regressions


# Setup mail
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        exim4 
COPY res/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf
RUN service exim4 restart


# CakeML
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        col 


# Cleanup
RUN apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/


