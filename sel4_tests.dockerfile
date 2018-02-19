# Get and compile all configs for seL4 test
ARG SEL4_IMG=trustworthysystems/sel4
FROM $SEL4_IMG

RUN mkdir -p /root/sel4test

WORKDIR /root/sel4test

ARG SCM=https://github.com

RUN /scripts/repo/repo init -u ${SCM}/sel4/sel4test-manifest.git \
    && /scripts/repo/repo sync

RUN err=false; for i in $(find configs/ -type f \( -iname "*defconfig" ! -name "bamboo_*" \) | sort ); \
    do \
        echo $(basename $i) \
        && make mrproper          2>&1 1>/dev/null \
        && make $(basename $i)    2>&1 1>/dev/null \
        && make silentoldconfig   2>&1 1>/dev/null \
        && make -j 2              2>&1 1>/dev/null \
        || err=true; \
    done; \
    if [ "$err" = true ]; then \
        echo "ERROR!"; \
        exit 1; \
    fi

