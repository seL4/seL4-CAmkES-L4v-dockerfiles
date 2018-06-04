# Run camkes tests
ARG BASE_IMG=trustworthysystems/camkes
FROM $BASE_IMG
MAINTAINER Luke Mondy (luke.mondy@data61.csiro.au)

WORKDIR /root/sel4test

ARG SCM=https://github.com

# This project contains some non-ascii filenames.
# Python (ie. repo) explodes when it encounters such a filename unless locales are set up.
ENV LC_ALL=en_AU.UTF-8

# TODO: Rewrite tests for new build system
#RUN /scripts/repo/repo init -u ${SCM}/sel4/camkes-manifest.git \
#    && /scripts/repo/repo sync

#RUN /usr/bin/env python tests/run-all-xml.py --jobs=1 | tee results.xml
