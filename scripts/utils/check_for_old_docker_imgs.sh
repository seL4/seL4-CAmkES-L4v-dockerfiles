#!/usr/bin/env bash
#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

# Check if the docker image given as argument, tagged as 'latest', is
# getting older than MAX_AGE_IN_DAYS. If so, print a short message.

if [ $# -ne 1 ]; then
    echo 1>&2 "Usage: $0 trustworthysystems/img"
    exit 1
fi

img_ref="$1:latest"

MAX_AGE_IN_DAYS=30

# Cutoff date as YYYYMMDD. Try BSD date first (-v), then GNU date (--date).
cutoff=$(date -v-${MAX_AGE_IN_DAYS}d +%Y%m%d 2> /dev/null \
    || date --date="${MAX_AGE_IN_DAYS} days ago" +%Y%m%d)

if [ -z "$cutoff" ]; then
    echo 1>&2 "WARNING: Skipping the docker image age check. date command did not behave as expected."
    exit 0
fi

img_iso=$(docker inspect --format='{{json .Created}}' "$img_ref" 2> /dev/null | tr -d '"')
if [ -z "$img_iso" ]; then
    # Image not present locally; nothing to check.
    exit 0
fi

# img_iso is of the form YYYY-MM-DDTHH:MM:SS.ssssssZ; use only YYYY-MM-DD part
img_day="${img_iso%%T*}"
# remove `-`
img_num=$(echo "$img_day" | tr -d -)

# numeric comparison on YYYYMMDD
if [ "$img_num" -lt "$cutoff" ]; then
    echo 1>&2 "WARNING: The docker image:"
    echo 1>&2 "           $img_ref"
    echo 1>&2 "         is older than ${MAX_AGE_IN_DAYS} days."
    echo 1>&2 "         You should consider updating it or choosing a specific tag."
fi
