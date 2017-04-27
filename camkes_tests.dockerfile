# Run camkes tests
FROM trustworthysystems/camkes
MAINTAINER Luke Mondy (luke.mondy@data61.csiro.au)

WORKDIR /root/sel4test

ARG SCM=https://github.com

# This project contains some non-ascii filenames.
# Python (ie. repo) explodes when it encounters such a filename unless locales are set up.
ENV LC_ALL=en_AU.UTF-8

RUN /scripts/repo/repo init -u ${SCM}/sel4/camkes-manifest.git \
    && /scripts/repo/repo sync

RUN chmod +x tests/run-all-xml.sh

RUN ./tests/run-all-xml.sh
