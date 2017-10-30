# Get and compile all configs for seL4 test
FROM trustworthysystems/sel4

RUN mkdir -p /root/sel4test

WORKDIR /root/sel4test

ARG SCM=https://github.com

RUN /scripts/repo/repo init -u ${SCM}/sel4/sel4test-manifest.git \
    && /scripts/repo/repo sync

RUN for i in $(find configs/ -type f \( -iname "*defconfig" ! -name "bamboo_*" \) | sort ); \
    do \
        echo $(basename $i) \
        && make mrproper > /dev/null 2>&1 \
        && make $(basename $i) > /dev/null 2>&1  \
        && make silentoldconfig > /dev/null 2>&1  \
        && make -j 2 > /dev/null 2>&1;  \
    done

