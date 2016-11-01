# Docker image for seL4 
FROM base_tools_gcc5

# Get unstable sources
RUN echo "deb http://deb.debian.org/debian sid main" >> /etc/apt/sources.list 
COPY res/unstable /etc/apt/preferences.d/unstable

# Add ARM archs
RUN dpkg --add-architecture armhf \
    && dpkg --add-architecture armel 

# Get the basics for seL4 build system
RUN apt-get update -q --no-install-recommends \
    && apt-get install -y \
        build-essential \
        cpio \
        ccache \
        gcc-6-base \
        gcc-5 \
        gcc-5-multilib \
        gcc-5-arm-linux* \
        g++-5-arm-linux* \
        binutils-arm-none-eabi \
        gcc-arm-none-eabi/unstable \
        libcc1-0 \
        libxml2-utils \
        ncurses-dev \
        python-tempita \ 
        qemu \
        realpath \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Get six for Python
RUN pip install --allow-all-external \
        six

# Set default compiler to be gcc5
COPY res/set_default_cc_to_gcc5.sh /root/set_default_cc_to_gcc5.sh
RUN chmod +x /root/set_default_cc_to_gcc5.sh \
    && /root/set_default_cc_to_gcc5.sh \
    && rm /root/set_default_cc_to_gcc5.sh \
    && gcc --version

