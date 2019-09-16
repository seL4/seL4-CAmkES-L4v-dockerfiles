ARG BASE_IMG=trustworthysystems/camkes

FROM $BASE_IMG 

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

RUN git clone https://github.com/NICTA/cogent.git \
    && cd cogent/cogent/ \
    && stack build \
    && stack install

ENV PATH "$PATH:/root/.local/bin"

