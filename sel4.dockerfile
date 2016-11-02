# Docker image for seL4 
FROM base_tools_gcc5

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
        g++-5-arm-linux* \
        gcc-arm-none-eabi \
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

