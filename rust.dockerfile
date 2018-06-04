ARG BASE_IMG=trustworthysystems/camkes
FROM $BASE_IMG

RUN wget -O - https://sh.rustup.rs > /root/rustup.sh \
    && sh /root/rustup.sh -y --default-toolchain nightly \
    && $HOME/.cargo/bin/rustup target add x86_64-rumprun-netbsd

ENV PATH "$PATH:$HOME/.cargo/bin"

