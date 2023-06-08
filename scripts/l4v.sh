#!/bin/bash
#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -exuo pipefail

# make sure PATH etc is set up
# shellcheck disable=SC1091
source "$HOME/.bashrc"

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

# Get l4v and setup isabelle
try_nonroot_first mkdir "$ISABELLE_DIR" || chown_dir_to_user "$ISABELLE_DIR"
ln -s "$ISABELLE_DIR" "$HOME/.isabelle"
mkdir -p "$HOME/.isabelle/etc"

ISABELLE_SETTINGS_LOCATION="$HOME/.isabelle/etc/settings"
cp "$NEW_ISABELLE_SETTINGS" "$ISABELLE_SETTINGS_LOCATION"

# MLton is needed for the L4v C parser. It is a default component for Isabelle,
# so we point PATH directly there. The component will only be available by
# default if the cache below is installed or if the components are later
# installed by the user. To run anything in L4v one has to install components,
# so the path assignment here will be useful even without the cache.
# The component name/version is stable enough to update manually when it changes.
export PATH="/isabelle/contrib/mlton-20210117-1/x86_64-linux/bin/":"$PATH"

if [ "$MAKE_CACHES" = "yes" ] ; then
    # Get a copy of the L4v repo, and build all the isabelle and haskell
    # components, so we have them cached.
    mkdir -p "$TEMP_L4V_LOCATION"
    pushd "$TEMP_L4V_LOCATION"
        repo init -u "${SCM}/seL4/verification-manifest.git" --depth=1
        repo sync -c
        pushd l4v
            ./isabelle/bin/isabelle components -a

            # Isabelle downloads tar.gz files, and then uncompresses them for
            # its contrib. We don't need both the uncompressed AND decompressed
            # versions, but Isabelle checks for the tarballs. To fool it, we now
            # truncate the tars and save disk space. We also remove the large
            # vscodium component, which is not needed for command line builds.
            # This will lead to a warning when Isabelle starts, which is safe to
            # ignore.
            pushd "$HOME/.isabelle/contrib"
                truncate -s0 ./*.tar.gz
                rm -r vscodium-*
                ls -lah  # show the evidence
            popd

            pushd spec/haskell
                make sandbox
            popd
        popd
    popd

    # Now cleanup the stuff we don't want cached
    rm -rf "$TEMP_L4V_LOCATION"
    as_root rm -rf /tmp/isabelle-  # This is a random tmp folder isabelle makes
fi

possibly_toggle_apt_snapshot
