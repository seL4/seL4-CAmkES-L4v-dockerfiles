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
        gcc-5-multilib \
        gcc-5-arm-linux* \
        g++-5-arm-linux* \
        gcc-arm-none* \  
        libxml2-utils \
        ncurses-dev \
        python-pip \
        python-tempita \ 
        qemu \
        realpath 

# Get six for Python
RUN pip install --allow-all-external \
        six


# Cleanup
RUN apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

