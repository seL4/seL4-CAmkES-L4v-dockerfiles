ARG CAMKES_IMG=trustworthysystems/camkes
FROM $CAMKES_IMG

RUN curl https://sh.rustup.rs -sSf > /root/rustup.sh \
    && sh /root/rustup.sh -y --default-toolchain nightly \
    && $HOME/.cargo/bin/rustup target add x86_64-rumprun-netbsd

ENV PATH "$PATH:$HOME/.cargo/bin"

