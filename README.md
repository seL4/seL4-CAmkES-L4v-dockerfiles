# Dockerfiles for seL4, CAmkES, and L4v dependencies

## TL;DR:
To get a running build environment for sel4 and camkes, run:

    make user

Or to map a particular directory to the /host dir in the container:

    make user HOST_DIR=/scratch/sel4_stuff  # as an example

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
    make user_camkes  # alias for 'make user'
    make user_l4v

The container will map the current working directory from the host to /host within the container. You should be able to read and write files, as the container copies your username and UID.

If you want to map a different folder, you can specify it on the command line:

    make user_sel4 HOST_DIR=/scratch/sel4_stuff

## Security
Running Docker on your machine has its own security risks which you should be aware of. Of particular note in this case, your UID and GID are being baked into an image that exists for the lifetime of your session. Any other user on the host who is part of the docker group could spawn a seperate container of this image, and hence have read and write access to your files.
Use at your own risk.
