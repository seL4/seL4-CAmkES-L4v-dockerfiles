ARG BASE_IMG=trustworthysystems/camkes
FROM $BASE_IMG

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"
LABEL PREBUILT="yes"

# Set up tools to compile CakeML
RUN git clone https://github.com/HOL-Theorem-Prover/HOL.git \
    && cd HOL \
    && git checkout 7323105f50960bdec1b33c513576e5d1d313b62f \
    && mkdir -p tools-poly \
    && echo "val polymllibdir = \"/usr/lib/x86_64-linux-gnu/\";" > tools-poly/poly-includes.ML \
    && poly < tools/smart-configure.sml \
    && bin/build \
    && chmod -R 757 /HOL

ENV PATH "$PATH:$HOME/HOL/bin"

RUN wget https://cakeml.org/regression/artefacts/473/cake-x64-32.tar.gz \
    && tar -xvzf cake-x64-32.tar.gz \
    && cd cake-x64-32 \
    && make cake \
    && rm /cake-x64-32.tar.gz

RUN wget https://cakeml.org/regression/artefacts/473/cake-x64-64.tar.gz \
    && tar -xvzf cake-x64-64.tar.gz \
    && cd cake-x64-64 \
    && make cake \
    && rm /cake-x64-64.tar.gz

RUN git clone https://github.com/CakeML/cakeml.git \
    && cd cakeml \
    && git checkout 66a35311787bb43f72e8e758209a4745f288cdfe \
    # Pre-build the following cakeml directories to speed up subsequent cakeml app builds
    && for dir in "characteristic" "basis" "misc" "translator" "semantics" "unverified/sexpr-bootstrap" \
    "compiler/parsing" "semantics/proofs"; \
        do \
            cd /cakeml/${dir} && /HOL/bin/Holmake; \
        done \
    && chmod -R 757 /cakeml
