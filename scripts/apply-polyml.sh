#!/bin/bash
#
# Copyright 2025, Proofcraft Pty Ltd
#
# SPDX-License-Identifier: BSD-2-Clause
#

# Install PolyML from GitHub source

set -exuo pipefail

version="5.7.1"
url="https://github.com/polyml/polyml/archive/refs/tags/v${version}.tar.gz"
TMP_DIR="/tmp"

wget -4 "${url}" --directory-prefix="$TMP_DIR"

pushd "$TMP_DIR"
tar -xzf "v${version}.tar.gz"
pushd "polyml-${version}"
# patch polyml-5.7.1 for glibc 2.34+
sed -i 's|#if (PTHREAD_STACK_MIN < 4096)|#if 0|' libpolyml/sighandler.cpp
# Force HAVE_ASM_ELF_H to no for polyml-5.7.1; comment says Android only
# https://github.com/polyml/polyml/blob/v5.7.1/libpolyml/elfexport.cpp#L93-L96
./configure --prefix=/usr ac_cv_header_asm_elf_h=no
make
make install
rm -rf "v${version}.tar.gz" "polyml-${version}"
popd
popd
