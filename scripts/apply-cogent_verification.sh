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

# Where will cogent libraries go
: "${COGENT_DIR:=/usr/local/cogent}"

# Autocorres version
: "${AC_VER:=autocorres-1.6.1}"
: "${AC_DIR:=$COGENT_DIR/autocorres}"

if [[ ! -d $COGENT_DIR ]]; then
    echo "No COGENT_DIR found! You need to run the apply-cogent.sh script first!"
    exit 1
fi

# Not strictly necessary, but it makes the apt operations in
# ../dockerfiles/apply-cogent_verification.dockerfile work.
as_root apt-get update -q

as_root pip3 install --no-cache-dir \
    ruamel.yaml \
    termcolor
    # end of list

export PATH="$PATH:/opt/ghc/bin:/opt/cabal/bin"
pushd "$COGENT_DIR"
    git submodule update --init --depth 1 --recursive -- isabelle
    ln -s "$PWD/isabelle/bin/isabelle" /usr/local/bin/isabelle

    isabelle components -I
    isabelle components -a

    wget "http://ts.data61.csiro.au/projects/TS/autocorres/${AC_VER}.tar.gz"
    tar -xf "${AC_VER}.tar.gz" && rm "${AC_VER}.tar.gz"
    mv "${AC_VER}" "${AC_DIR}"

    pushd cogent
        sed -i 's/^jobs:.*$/jobs: 2/' "$HOME/.cabal/config"
        #cp misc/cabal.config.d/cabal.config-8.6.5 cabal.config

        cabal v1-install --only-dependencies --force-reinstalls --enable-tests --dry -v --flags="haskell-backend docgent"
        cabal v1-install --only-dependencies --force-reinstalls --flags="haskell-backend docgent";  # --enable-tests;
        cabal v1-configure --flags="haskell-backend docgent"
        cabal v1-install --force-reinstalls --flags="haskell-backend docgent"
    popd
popd

# Isabelle downloads tar.gz files, and then uncompresses them for its contrib.
# We don't need both the uncompressed AND decompressed versions, but Isabelle
# checks for the tarballs. To fool it, we now truncate the tars and save disk space.
pushd "$HOME/.isabelle/contrib"
    truncate -s0 ./*.tar.gz
    ls -lah  # show the evidence
popd
as_root rm -rf /tmp/isabelle-  # This is a random tmp folder isabelle makes
