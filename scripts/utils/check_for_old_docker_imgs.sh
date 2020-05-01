#!/bin/bash

# Check if any Trustworthy Systems docker images, tagged as 'latest', are getting a bit old
# If so, print a short message


# Do a test with a random date to make sure this function will work
# TODO: implement different date functions for different OSs
date --date="2020-04-25T18:44:40.822475865Z" &> /dev/null
if [ ! $? -eq 0 ]; then
    echo 1>&2 "Using the date command failed - unable to check if your trustworthysystems docker images are getting a bit old!"
    exit 0
fi

# Loop through the images available
for img in $(docker images --filter=reference='trustworthysystems/*:latest' -q); do
    today="$(date +%s)"
    img_created_date="$(date --date=$(docker inspect --format='{{json .Created}}' "$img" | tr -d '"') +%s)"
    time_delta_in_days="$(( ( $today - $img_created_date ) / (60*60*24) ))"

    if [ $time_delta_in_days -gt 30 ]; then
        echo "The docker image: $(docker inspect --format='{{(index .RepoTags 0)}}' $img ) is getting a bit old (more than 30 days)."
        echo "You should consider updating it, or choosing a specific tag."
        sleep 2
    fi
done
