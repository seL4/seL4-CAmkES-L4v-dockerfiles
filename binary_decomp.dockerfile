ARG BASE_IMG=trustworthysystems/sel4
FROM $BASE_IMG

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"

RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        autoconf \
        gperf \
        libgmp-dev \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ \
    && mkdir /smtsolvers

WORKDIR /smtsolvers

RUN git clone https://github.com/SRI-CSL/yices2 \
    && cd yices2 \
    && git checkout -b yices-260 Yices-2.6.0 \
    && autoconf \
    && mkdir deploy \
    && ./configure --prefix="$PWD"/deploy \
    && make \
    && make install

RUN wget http://downloads.ssrg.nicta.com.au/downloads/isabelle/components/cvc4-1.5-3.tar.gz \
    && wget http://www.informatik.uni-bremen.de/agbs/florian/sonolar/sonolar-2014-12-04-x86_64-linux.tar.gz \
    && echo bf3bb4de0d3b39503de436f4385c7a8b8040626addebff5c230b4f4f929ae358 sonolar-2014-12-04-x86_64-linux.tar.gz > checksums \
    && echo a3343c4255ac2d1f64f83d4feba2ed076da23e429f145da0066a9cd66e932162 cvc4-1.5-3.tar.gz >> checksums \
    && if sha256sum -c checksums; then \
           echo 'Checked checksums'; \
       else \
           echo 'Bad SHA hash!'; \
           exit 1; \
       fi \
    && tar -xvzf cvc4-1.5-3.tar.gz \
    && tar -xvzf sonolar-2014-12-04-x86_64-linux.tar.gz \
    && echo CVC4: online: /smtsolvers/cvc4-1.5-3/x86_64-linux/cvc4 --incremental --lang smt --tlimit=5000 > solverlist \
    && echo SONOLAR: offline: /smtsolvers/sonolar-2014-12-04-x86_64-linux/bin/sonolar --input-format=smtlib2 >> solverlist \
    && echo CVC4: offline: /smtsolvers/cvc4-1.5-3/x86_64-linux/cvc4 --lang smt >> solverlist \
    && echo SONOLAR-word8: offline: /smtsolvers/sonolar-2014-12-04-x86_64-linux/bin/sonolar --input-format=smtlib2 >> solverlist \
    && echo   config: mem_mode = 8 >> solverlist \
    && echo Yices2: offline: /smtsolvers/yices2/deploy/bin/yices-smt2 >> solverlist \
    && echo Yices2-word8: offline: /smtsolvers/yices2/deploy/bin/yices-smt2 >> solverlist \
    && echo   config: mem_mode = 8 >> solverlist

