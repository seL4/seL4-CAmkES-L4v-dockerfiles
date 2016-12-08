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
        gcc-5-arm-linux-gnueabi \
        gcc-5-arm-linux-gnueabihf \
        gcc-arm-none-eabi \
        g++-5 \
        g++-5-arm-linux-gnueabi \
        g++-5-arm-linux-gnueabihf \
        libcc1-0 \
        libxml2-utils \
        ncurses-dev \
        python-tempita \ 
        qemu \
        realpath \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Set default compiler to be gcc-5
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
    done

# Set gcc-5-arm compilers to be default (even though there are no others)
RUN for compiler in gcc-5-arm-linux-gnueabi \
                    cpp-5-arm-linux-gnueabi \
                    gcc-5-arm-linux-gnueabihf \
                    cpp-5-arm-linux-gnueabihf \
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
RUN pip install \
        ply \
        six

