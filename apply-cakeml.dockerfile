ARG BASE_BUILDER_IMG=trustworthysystems/prebuild-cakeml
ARG BASE_IMG=trustworthysystems/sel4

FROM $BASE_BUILDER_IMG as builder
# Load the prebuilt compilers as a throwaway container (named 'builder')

FROM $BASE_IMG 

COPY --from=builder /HOL /HOL
COPY --from=builder /cake-x64-32 /cake-x64-32
COPY --from=builder /cake-x64-64 /cake-x64-64
COPY --from=builder /cakeml /cakeml


ENV PATH "$PATH:$HOME/HOL/bin"
