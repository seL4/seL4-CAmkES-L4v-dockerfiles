ARG L4V_IMG=trustworthysystems/l4v
FROM $L4V_IMG

RUN mkdir -p /root/verification

ARG SCM=https://github.com

WORKDIR /root/verification

RUN /scripts/repo/repo init -u ${SCM}/seL4/verification-manifest.git \
    && /scripts/repo/repo sync

WORKDIR /root/verification/l4v

CMD ./run_tests

