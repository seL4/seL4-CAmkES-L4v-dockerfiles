# Dependencies for compiling seL4
FROM base_tools
MAINTAINER Luke Mondy (luke.mondy@data61.csiro.au)


# gcc-5-arm tools have been moved to unstable :(
# Add the apt sources for unstable, and put in a preference for using unstable
# only for the packages we need 
RUN head -n 1 /etc/apt/sources.list | sed -e 's/stretch/sid/g' > /etc/apt/sources.list.d/sid.list \
    && echo 'Package: *' >> /etc/apt/preferences \
    && echo 'Pin: release a=stable' >> /etc/apt/preferences \
    && echo 'Pin-Priority: 900' >> /etc/apt/preferences \
    && echo '' >> /etc/apt/preferences \
    && echo 'Package: *' >> /etc/apt/preferences \
    && echo 'Pin: release a=unstable' >> /etc/apt/preferences \
    && echo 'Pin-Priority: 800' >> /etc/apt/preferences 

RUN dpkg --add-architecture armhf \
    && dpkg --add-architecture armel \
    && apt-get update -q \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ccache \
        cmake \
        cpio \
        g++-5 \
        gcc-5-multilib \
        gcc-6-base \
        gcc-arm-none-eabi \
        libcc1-0 \
        libxml2-utils \
        ncurses-dev \
        qemu \
        realpath \
        # All the below packages need to come from UNSTABLE!
        binutils-aarch64-linux-gnu/sid \
        binutils/sid \
        g++-5-aarch64-linux-gnu/sid \
        g++-5-arm-linux-gnueabi/sid \
        g++-5-arm-linux-gnueabihf/sid \
        gcc-5-aarch64-linux-gnu/sid \
        gcc-5-arm-linux-gnueabi/sid \
        gcc-5-arm-linux-gnueabihf/sid \
        gcc-5/sid \
        libasan2-armel-cross/sid \
        libasan2-armhf-cross/sid \
        libc6-dev-arm64-cross/sid \
        libc6-dev-armel-cross/sid \
        libc6-dev-armhf-cross/sid \
        libgcc-5-dev-armel-cross/sid \
        libgcc-5-dev-armhf-cross/sid \
        libstdc++-5-dev-arm64-cross/sid \
        libstdc++-5-dev-armel-cross/sid \
        libstdc++-5-dev-armhf-cross/sid \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Set default compiler to be gcc-5 (not 6), and 
# set gcc-5-arm compilers to be default (even though there are no others)
RUN for compiler in gcc \
                    g++; \
    do \
        for file in $(dpkg-query -L ${compiler} | grep /usr/bin/); \
        do \
            name=$(basename ${file}); \
            echo "$name - $file"; \
            update-alternatives --install "${file}" "${name}" "${file}-5" 60; \
            update-alternatives --install "${file}" "${name}" "${file}-6" 50; \
            update-alternatives --auto "${name}"; \
        done \
    done \
    && \
    for compiler in gcc-5-arm-linux-gnueabi \
                    cpp-5-arm-linux-gnueabi \
                    gcc-5-aarch64-linux-gnu \
                    cpp-5-aarch64-linux-gnu \
                    gcc-5-arm-linux-gnueabihf \
                    cpp-5-arm-linux-gnueabihf \
                    g++-5-aarch64-linux-gnu \
                    g++-5-arm-linux-gnueabi \
                    g++-5-arm-linux-gnueabihf; \
    do \
        echo ${compiler}; \
        for file in $(dpkg-query -L ${compiler} | grep /usr/bin/); \
        do \
            name=$(basename ${file} | sed 's/-5$//g'); \
            link=$(echo ${file} | sed 's/-5$//g'); \
            echo "$name - $file"; \
            update-alternatives --install "${link}" "${name}" "${file}" 60; \
            update-alternatives --auto "${name}"; \
        done \
    done


# Get Python deps
RUN for p in "pip" "python3 -m pip"; \
    do \
        ${p} install \
            sel4-deps; \
    done

