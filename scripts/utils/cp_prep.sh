#!/bin/sh
#
# Copyright 2021, Nataliya Korovkina, malus.brandywine@gmail.com
#
# SPDX-License-Identifier: BSD-2-Clause
#


SDK_DIR=/host/sel4-core-platform

SEL4_URL="https://github.com/BreakawayConsulting/seL4.git"
SEL4_BRANCH_NAME="sel4cp-core-support"
SEL4_SRC_DIR=${SDK_DIR}/sel4_cp_support

CP_URL="https://github.com/BreakawayConsulting/sel4cp.git"
CP_BRANCH_NAME=""
CP_DIR=${SDK_DIR}/sel4cp


mkdir -p ${SEL4_SRC_DIR} ;mkdir -p ${CP_DIR}

# Getting proper seL4
git clone -b ${SEL4_BRANCH_NAME} ${SEL4_URL} ${SEL4_SRC_DIR}

# Getting core platform source
git clone ${CP_URL} ${CP_DIR}

# Local python env
cd ${SDK_DIR}; python3.9 -m venv pyenv; \
        ./pyenv/bin/pip install --upgrade pip setuptools wheel; \
        ./pyenv/bin/pip install sel4-deps; \
        ./pyenv/bin/pip install -r ${CP_DIR}/requirements.txt

