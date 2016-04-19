# Docker image for seL4 
FROM base_tools

# Use the emdebian packages
RUN mkdir -p /etc/apt/sources.list.d \
    && echo "deb http://emdebian.org/tools/debian/ jessie main" > /etc/apt/sources.list.d/crosstools.list \
    && curl http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -

# Add ARM archs
RUN dpkg --add-architecture armhf \
    && dpkg --add-architecture armel \
    && apt-get update -q 

# Get the basics for seL4 build system
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cpio \
        ccache \
        gcc-4.9-multilib \
        libxml2-utils \
        ncurses-dev \
        python-pip \
        python-tempita \ 
        realpath 

# Get six for Python
RUN pip install --allow-all-external \
        six


# Get cross compilers
RUN apt-get install -y --no-install-recommends \
        crossbuild-essential-armel \
        crossbuild-essential-armhf \
        gcc-arm-none-eabi \
        qemu
    
RUN ln -s /usr/bin/arm-linux-gnueabi-cpp-4.9 /usr/bin/arm-linux-gnueabi-cpp


# Cleanup
RUN apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

