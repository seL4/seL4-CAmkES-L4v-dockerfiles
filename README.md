# Dockerfiles for seL4, CAmkES, and L4v dependencies

## TL;DR:

To get a running build environment for sel4 and camkes, run:

    make user

This may take a while.

## To build:

To build all the images, run:

    make all

To build a specific image, specify it with make:

    make sel4
    make camkes
    make l4v

## To run:

To get an environment within the container, run:

    make user

which will give you a terminal with camkes dependencies built. You can be more specific with:

    make user_sel4
    make user_camkes  # same as make user
    make user_l4v

The container will map the current working directory from the host to /host within the container. You should be able to read and write files, as the container copies your username and UID.

If you want to map a different folder, you can specify it on the command line:

    make user_sel4 HOST_DIR=/scratch/sel4_stuff


