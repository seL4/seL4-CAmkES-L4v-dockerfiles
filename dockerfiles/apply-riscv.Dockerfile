ARG BASE_BUILDER_IMG=trustworthysystems/prebuilt_riscv_compilers
ARG BASE_IMG=trustworthysystems/sel4

FROM $BASE_BUILDER_IMG as builder
# Load the prebuilt compilers as a throwaway container (named 'builder')

FROM $BASE_IMG 

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

COPY --from=builder /opt/riscv /opt/riscv

ENV RISCV /opt/riscv
ENV PATH "$PATH:$RISCV/bin"
