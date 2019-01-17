ARG BASE_IMG=trustworthysystems/camkes
FROM $BASE_IMG

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

# Get rust nightly
RUN wget -O - https://sh.rustup.rs > /root/rustup.sh \
    && sh /root/rustup.sh -y --default-toolchain nightly \
    && $HOME/.cargo/bin/rustup target add x86_64-rumprun-netbsd

ENV PATH "$PATH:$HOME/.cargo/bin"
