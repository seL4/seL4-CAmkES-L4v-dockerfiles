FROM verification

COPY res/verification_settings /root/.isabelle/etc/settings

RUN mkdir -p /root/verification
WORKDIR /root/verification

RUN /scripts/repo/repo init -u https://github.com/seL4/verification-manifest.git \
    && /scripts/repo/repo sync

WORKDIR /root/verification/l4v

CMD ./run_tests

