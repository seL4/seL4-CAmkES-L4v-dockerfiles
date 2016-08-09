# Docker image for seL4 
FROM base_tools_gcc5

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
        gcc-5-multilib \
        gcc-arm-linux* \
        g++-arm-linux* \
        gcc-arm-none* \
        qemu
    
#RUN ln -s /usr/bin/arm-linux-gnueabi-cpp-4.9 /usr/bin/arm-linux-gnueabi-cpp


# Cleanup
RUN apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

