ARG BASE_IMG=trustworthysystems/camkes
FROM $BASE_IMG

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Luke Mondy (luke.mondy@data61.csiro.au)"


# Get deps required for VisualCAmkES
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        graphviz \
        python-pyqt5 \
        python-pyqt5.qtsvg \
        xauth \
        xvfb \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ \
    && for p in "pip2" "pip3"; \
        do \
            ${p} install --no-cache-dir \
                ansi2html \
                graphviz \
                pydotplus; \
        done
