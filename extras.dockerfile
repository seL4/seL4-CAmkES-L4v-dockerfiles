FROM trustworthysystems/sel4

# This dockerfile is a shim between the images from Dockerhub and the 
# user.dockerfile.
# Add extra dependencies in here!

# For example, uncomment this to get cowsay on top of the sel4/camkes/l4v
# dependencies:

# RUN apt-get update -q \
#     && apt-get install -y --no-install-recommends \
#         cowsay \
#     && apt-get clean autoclean \
#     && apt-get autoremove --yes \
#     && rm -rf /var/lib/{apt,dpkg,cache,log}/
#
# RUN /usr/games/cowsay "Trustworthy Systems!"
