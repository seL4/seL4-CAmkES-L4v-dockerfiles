#
# Copyright 2021, Nataliya Korovkina, malus.brandywine@gmail.com
#
# SPDX-License-Identifier: BSD-2-Clause
#

ARG USER_BASE_IMG=trustworthysystems/sel4
FROM $USER_BASE_IMG

#
# Take care of python3 version & other missing packages
#

RUN apt update
RUN apt-get -y install python3.9 python3.9-venv
RUN apt-get -y install pandoc texlive-latex-base texlive-latex-extra
RUN apt-get -y install rsync


#
# Take care of cross compilation tools, version 10.2-2020.11
#

ARG TMP_DIR=/tmp/gcc-x86_64-aarch64-none-elf

# destination directory for the tools' binaries
ARG GCC_BIN_DIR=/usr/local/gcc-x86_64-aarch64-none-elf

ARG GCC_PREBUILT_TGZ=gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz
ARG GCC_PREBUILT_TGZ_URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz?revision=79f65c42-1a1b-43f2-acb7-a795c8427085&hash=61BBFB526E785D234C5D8718D9BA8E61"

ARG GCC_PREBUILT_ASC=gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz.asc
ARG GCC_PREBUILT_ASC_URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz.asc?revision=99909d67-54df-42bb-ae0e-bff40ffdc8ea&hash=FF86380F05240E4994917727CD7D3C2D"

# The directory name the archive will be exctracted to
ARG GCC_BIN_DIR_VERSIONED=gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf

RUN mkdir ${TMP_DIR}
RUN mkdir ${GCC_BIN_DIR}

RUN wget -nv --tries=10 -O ${TMP_DIR}/${GCC_PREBUILT_TGZ} ${GCC_PREBUILT_TGZ_URL}
RUN wget -nv --tries=10 -O ${TMP_DIR}/${GCC_PREBUILT_ASC} ${GCC_PREBUILT_ASC_URL}

RUN tar -xJf ${TMP_DIR}/${GCC_PREBUILT_TGZ} -C ${TMP_DIR}

RUN cd ${TMP_DIR}; md5sum --check ${GCC_PREBUILT_ASC}

RUN rsync -a ${TMP_DIR}/${GCC_BIN_DIR_VERSIONED}/  ${GCC_BIN_DIR}/

RUN echo "export PATH=${GCC_BIN_DIR}/bin:\$PATH\n" >> /root/.bashrc


#
# Take care of musl library, we take the latest one
#

ARG MUSL_DIR=/usr/local/musl
ARG MUSL_ARCH=aarch64
ARG MUSL_GIT_DIR="git://git.musl-libc.org/musl"
ARG MUSL_BUILD_DIR=/tmp/musl.build


RUN mkdir ${MUSL_BUILD_DIR}
RUN git clone ${MUSL_GIT_DIR} ${MUSL_BUILD_DIR}

RUN . ~/.bashrc; cd ${MUSL_BUILD_DIR}; \
    ./configure  \
--prefix=${MUSL_DIR}/${MUSL_ARCH} --enable-wrapper=gcc

RUN . ~/.bashrc; make -C ${MUSL_BUILD_DIR}
RUN . ~/.bashrc; make -C ${MUSL_BUILD_DIR} install


RUN echo "export PATH=${MUSL_DIR}/${MUSL_ARCH}/bin:\$PATH\n" >> /root/.bashrc

#
# Copy shell script cp_init.sh to get proper project sources
# and build local python environment
#

COPY scripts/utils/cp_prep.sh /tmp/
