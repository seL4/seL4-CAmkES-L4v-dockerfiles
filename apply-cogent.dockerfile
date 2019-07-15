ARG BASE_IMG=trustworthysystems/camkes

FROM $BASE_IMG as builder

RUN git clone https://github.com/NICTA/cogent.git \
    && cd cogent/cogent/ \
    && sed -i '/package-indices/,+3 d' stack.yaml \
    && stack build \
    && stack install


FROM $BASE_IMG 

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

COPY --from=builder /root/.local/bin/cogent /usr/local/bin/cogent
