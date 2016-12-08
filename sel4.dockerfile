# Dependencies for compiling seL4
FROM base_tools
MAINTAINER Luke Mondy (luke.mondy@data61.csiro.au)

# Add ARM archs
RUN dpkg --add-architecture armhf \
    && dpkg --add-architecture armel 

# Get the basics for seL4 build system
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cpio \
        ccache \
        gcc-6-base \
        gcc-5 \
        gcc-5-multilib \
        gcc-5-arm-linux* \
        gcc-arm-none-eabi \
        g++-5 \
        g++-5-arm-linux* \
        libcc1-0 \
        libxml2-utils \
        ncurses-dev \
        python-tempita \ 
        qemu \
        realpath \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Get Python deps
RUN pip install \
        ply \
        six

# Set default compiler to be gcc-5
RUN for file in $(dpkg-query -L gcc | grep /usr/bin/); \
    do \
        name=$(basename ${file}); \
        echo "$name - $file"; \
        update-alternatives --install "${file}" "${name}" "${file}-5" 60; \
        update-alternatives --install "${file}" "${name}" "${file}-6" 50; \
        update-alternatives --auto "${name}"; \
    done 
