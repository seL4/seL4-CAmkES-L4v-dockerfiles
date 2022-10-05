#!/usr/bin/env bash
#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

# Check if any Trustworthy Systems docker images, tagged as 'latest', are getting a bit old
# If so, print a short message

MAX_AGE_IN_DAYS=30

linux_date_test() {
    date --date="2020-04-25T18:44:40.822475865Z" &> /dev/null
}

date_test() {
    # TODO: implement different date functions for different OSs
    linux_date_test
}

# Do a test with a random date to make sure this function will work
if ! date_test; then
    echo 1>&2 "WARNING: Unable to check if your trustworthysystems docker images are getting a bit old!"
    echo 1>&2 "         The date command did not behave as expected. Skipping the check."
    exit 0
fi

# Loop through the images available to determine if they're too old
for img in $(docker images --filter=reference='trustworthysystems/*:latest' -q); do
    today="$(date +%s)"
    img_created_date=$(date --date="$(docker inspect --format='{{json .Created}}' "$img" | tr -d '"')" +%s)
    time_delta_in_days="$(( ( today - img_created_date ) / (60*60*24) ))"

    if [ $time_delta_in_days -gt $MAX_AGE_IN_DAYS ]; then
        echo 1>&2 "WARNING: The docker image:"
        echo 1>&2 "           $(docker inspect --format='{{(index .RepoTags 0)}}' "$img" )"
        echo 1>&2 "         is getting a bit old (more than 30 days)."
        echo 1>&2 "         You should consider updating it, or choosing a specific tag."
    fi
done
