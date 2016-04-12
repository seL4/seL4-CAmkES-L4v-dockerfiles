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


# Get ready for test compilation
RUN mkdir /root/sel4test \
    && cd /root/sel4test \
    && /scripts/repo/repo init -u http://bitbucket.keg.ertos.in.nicta.com.au/scm/sel4/sel4test-manifest.git \
    && /scripts/repo/repo sync 

WORKDIR /root/sel4test

# Run test beagle compilation
RUN make beagle_debug_xml_defconfig \
    && make \
    && make clean

# Run test KZM compilation
RUN make kzm_debug_xml_defconfig \
    && make \
    && make clean

# Run test odroid-x compilation
RUN make odroidx_debug_xml_defconfig \
    && make \
    && make clean

# Run test odroid-xu compilation
RUN make odroidxu_debug_xml_defconfig \
    && make \
    && make clean

# Run test sabre compilation
RUN make sabre_debug_xml_defconfig \
    && make \
    && make clean

# Run test zynq7000 compilation
RUN make zynq7000_debug_xml_defconfig \
    && make \
    && make clean

# Run test ia32 compilation
RUN make ia32_debug_xml_defconfig \
    && make \
    && make clean



# Cleanup
RUN apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

