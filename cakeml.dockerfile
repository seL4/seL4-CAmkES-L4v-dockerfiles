ARG BASE_IMG=trustworthysystems/camkes
FROM $BASE_IMG

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"
LABEL PREBUILT="yes"

# Set up tools to compile CakeML
RUN git clone https://github.com/HOL-Theorem-Prover/HOL.git \
    && cd HOL \
    && git checkout 8384b1c70482d5fbd9ad4d83775cae2a05294515 \
    && mkdir -p tools-poly \
    && echo "val polymllibdir = \"/usr/lib/x86_64-linux-gnu/\";" > tools-poly/poly-includes.ML \
    && poly < tools/smart-configure.sml \
    && bin/build \
    && chmod -R 757 /HOL

ENV PATH "$PATH:$HOME/HOL/bin"

RUN wget https://cakeml.org/regression/artefacts/989/cake-x64-32.tar.gz \
    && tar -xvzf cake-x64-32.tar.gz \
    && cd cake-x64-32 \
    && make cake \
    && rm /cake-x64-32.tar.gz

RUN wget https://cakeml.org/regression/artefacts/989/cake-x64-64.tar.gz \
    && tar -xvzf cake-x64-64.tar.gz \
    && cd cake-x64-64 \
    && make cake \
    && rm /cake-x64-64.tar.gz

RUN git clone https://github.com/CakeML/cakeml.git \
    && cd cakeml \
    && git checkout 980410c6c89921c2e8950a5127bd9f32791f50bf \
    # Pre-build the following cakeml directories to speed up subsequent cakeml app builds
    && for dir in "basis" "compiler/parsing"; \
        do \
            cd /cakeml/${dir} && /HOL/bin/Holmake; \
        done \
    && chmod -R 757 /cakeml
