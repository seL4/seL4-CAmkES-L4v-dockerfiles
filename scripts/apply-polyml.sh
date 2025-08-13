#!/bin/bash
#
# Copyright 2025, Proofcraft Pty Ltd
#
# SPDX-License-Identifier: BSD-2-Clause
#

# Install PolyML from GitHub source

set -exuo pipefail

version="5.9.2"
url="https://github.com/polyml/polyml/archive/refs/tags/v${version}.tar.gz"
TMP_DIR="/tmp"

wget -4 "${url}" --directory-prefix="$TMP_DIR"

pushd "$TMP_DIR"
tar -xzf "v${version}.tar.gz"
pushd "polyml-${version}"
./configure --prefix=/usr
make
make install
rm -rf "v${version}.tar.gz" "polyml-${version}"
popd
popd
