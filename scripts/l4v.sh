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

# Don't make caches by default. Docker will set this to be 'yes'
: "${MAKE_CACHES:=no}"

# By default, assume we are on a desktop (usually less destructive)
: "${DESKTOP_MACHINE:=yes}"

# Docker may set this variable - fill if not set
: "${SCM:=https://github.com}"

# Some customisability for isabelle
: "${ISABELLE_DIR:=/isabelle}"
: "${NEW_ISABELLE_SETTINGS:=$DIR/../res/isabelle_settings}"

# tmp space for building L4v for caching
: "${TEMP_L4V_LOCATION:=/tmp/verification}"

possibly_toggle_apt_snapshot

as_root apt-get update -q
as_root apt-get install -y --no-install-recommends \
        librsvg2-bin \
        libwww-perl \
        libxslt-dev \
        libxml2-dev \
        openssh-client \
        mercurial \
        texlive-bibtex-extra \
        texlive-fonts-recommended \
        texlive-latex-extra \
        texlive-metapost \
        texlive-plain-generic \
        # end of list

# dependencies for testing
as_root apt-get install -y --no-install-recommends \
        less \
        python3-psutil \
        python3-lxml \
        # end of list

# looks like there is no Debian package for mlton any more
MLTON=mlton-20210117-1.amd64-linux-glibc2.31
wget https://github.com/MLton/mlton/releases/download/on-20210117-release/$MLTON.tgz
tar  -xzC /opt -f $MLTON.tgz
ln -s /opt/$MLTON opt/mlton
rm $MLTON.tgz

# Get l4v and setup isabelle
try_nonroot_first mkdir "$ISABELLE_DIR" || chown_dir_to_user "$ISABELLE_DIR"
ln -s "$ISABELLE_DIR" "$HOME/.isabelle"
mkdir -p "$HOME/.isabelle/etc"

ISABELLE_SETTINGS_LOCATION="$HOME/.isabelle/etc/settings"
cp "$NEW_ISABELLE_SETTINGS" "$ISABELLE_SETTINGS_LOCATION"

if [ "$MAKE_CACHES" = "yes" ] ; then
    # Get a copy of the L4v repo, and build all the isabelle and haskell
    # components, so we have them cached.
    mkdir -p "$TEMP_L4V_LOCATION"
    pushd "$TEMP_L4V_LOCATION"
        repo init -u "${SCM}/seL4/verification-manifest.git" --depth=1
        repo sync -c
        pushd l4v
            ./isabelle/bin/isabelle components -a
            pushd spec/haskell
                make sandbox
            popd
        popd
    popd

    # Now cleanup the stuff we don't want cached
    rm -rf "$TEMP_L4V_LOCATION"
    as_root rm -rf /tmp/isabelle-  # This is a random tmp folder isabelle makes

    # Isabelle downloads tar.gz files, and then uncompresses them for its contrib.
    # We don't need both the uncompressed AND decompressed versions, but Isabelle
    # checks for the tarballs. To fool it, we now truncate the tars and save disk space.
    pushd "$HOME/.isabelle/contrib"
        truncate -s0 ./*.tar.gz
        ls -lah  # show the evidence
    popd
fi

possibly_toggle_apt_snapshot
