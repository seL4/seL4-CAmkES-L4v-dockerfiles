#!/bin/bash
#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -exuo pipefail

# Source common functions
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD
# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

: "${SMTSOLVERS_DIR:=/usr/local/smtsolvers}"

possibly_toggle_apt_snapshot

as_root apt-get update -q
as_root apt-get install -y --no-install-recommends \
        autoconf \
        gperf \
        libgmp-dev \
        # end of list

try_nonroot_first mkdir "$SMTSOLVERS_DIR" || chown_dir_to_user "$SMTSOLVERS_DIR"
pushd "$SMTSOLVERS_DIR"
    CVC_TAR="cvc4-1.5-3.tar.gz"
    SONOLAR_TAR="sonolar-2014-12-04-x86_64-linux.tar.gz"

    # Force wget to use ipv4 as docker doesn't like ipv6
    wget -4 "https://isabelle.sketis.net/components/$CVC_TAR"  # TODO: get URL from isabelle settings
    wget -4 "http://www.informatik.uni-bremen.de/agbs/florian/sonolar/$SONOLAR_TAR"
    echo "bf3bb4de0d3b39503de436f4385c7a8b8040626addebff5c230b4f4f929ae358 $SONOLAR_TAR" > checksums
    echo "a3343c4255ac2d1f64f83d4feba2ed076da23e429f145da0066a9cd66e932162 $CVC_TAR" >> checksums
    if sha256sum -c checksums; then
        echo 'Checked checksums';
    else
        echo 'Bad SHA hash!';
        exit 1;
    fi
    tar -xvzf "$CVC_TAR" && rm "$CVC_TAR"
    tar -xvzf "$SONOLAR_TAR" && rm "$SONOLAR_TAR"

    tee solverlist << EOF
CVC4: online: /smtsolvers/cvc4-1.5-3/x86_64-linux/cvc4 --incremental --lang smt --tlimit=5000
SONOLAR: offline: /smtsolvers/sonolar-2014-12-04-x86_64-linux/bin/sonolar --input-format=smtlib2
CVC4: offline: /smtsolvers/cvc4-1.5-3/x86_64-linux/cvc4 --lang smt
SONOLAR-word8: offline: /smtsolvers/sonolar-2014-12-04-x86_64-linux/bin/sonolar --input-format=smtlib2
  config: mem_mode = 8
EOF
popd

possibly_toggle_apt_snapshot
