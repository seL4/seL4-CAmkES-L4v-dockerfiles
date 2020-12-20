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
        mlton \
        texlive-bibtex-extra \
        texlive-fonts-recommended \
        texlive-generic-extra \
        texlive-latex-extra \
        texlive-metapost \
        # end of list

# dependencies for testing
as_root apt-get install -y --no-install-recommends \
        less \
        python-psutil \
        python-lxml \
        # end of list


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

    # We need to fetch some additional components, so that both Isabelle2019 and 2020 have cached dependencies.
    # shellcheck disable=SC1090
    ISABELLE_COMPONENT_REPOSITORY=$(set +u; source "$ISABELLE_SETTINGS_LOCATION"; echo "$ISABELLE_COMPONENT_REPOSITORY")
    pushd ~/.isabelle/contrib
        for package in "csdp-6.x" \
                       "e-2.0-2" \
                       "isabelle_fonts-20190409" \
                       "jdk-11.0.3+7" \
                       "jedit_build-20190508" \
                       "opam-2.0.3-1" \
                       "polyml-5.8" \
                       "postgresql-42.2.5" \
                       "scala-2.12.7" \
                       "sqlite-jdbc-3.27.2.1" \
                       "stack-1.9.3" \
                       ; do
            wget "$ISABELLE_COMPONENT_REPOSITORY/$package.tar.gz"
            tar xvf "$package.tar.gz"
            # the tar files will be truncated below, so we don't need to delete them.
        done
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
