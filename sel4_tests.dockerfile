# Get and compile all configs for seL4 test
FROM selfour

RUN mkdir -p /root/sel4test

WORKDIR /root/sel4test

ARG SCM=https://github.com

RUN /scripts/repo/repo init -u ${SCM}/sel4/sel4test-manifest.git \
    && /scripts/repo/repo sync \
    && rm configs/ia32_release_xml_pae_defconfig \
    && rm configs/kzm_simulation_debug_xml_defconfig 

RUN make compile-all \
    && rm -rf /root/sel4test/*
