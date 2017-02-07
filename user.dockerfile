FROM selfour

MAINTAINER luke.mondy@data61.csiro.au

# Get user UID and username
ARG UID
ARG UNAME

# Create user matching host user
RUN useradd -u ${UID} ${UNAME}

# Create home folder
RUN mkdir /home/${UNAME} \
    && chown -R ${UNAME}:${UNAME} /home/${UNAME} \
    && chmod -R ug+rw /home/${UNAME} 


USER ${UNAME}

RUN echo 'echo "Hello, welcome to the sel4/CAmkES/L4v build environment"' >> ~/.bashrc

ENV PATH /scripts/repo/:$PATH

WORKDIR /host

# Ensure the home folder is saved in a volume
VOLUME /home/${UNAME}

CMD bash
