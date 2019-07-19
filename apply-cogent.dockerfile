ARG BASE_IMG=trustworthysystems/camkes

FROM $BASE_IMG 

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

# The sed line deletes this line:
# https://github.com/NICTA/cogent/blob/c40bd26b476b4694e5087063c1668d2a7062789f/cogent/stack.yaml#L13 
# and the 3 lines after it. This is so 'stack build' will work OK.

RUN git clone https://github.com/NICTA/cogent.git \
    && cd cogent/cogent/ \
    && sed -i '/package-indices/,+3 d' stack.yaml \
    && stack build \
    && stack install

ENV PATH "$PATH:$HOME/.local/bin"

