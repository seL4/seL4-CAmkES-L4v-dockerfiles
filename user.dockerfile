ARG EXTRAS_IMG=extras
FROM $EXTRAS_IMG

# Get user UID and username
ARG UID
ARG UNAME

# Crammed a lot in here to make building the image faster
RUN useradd -u ${UID} ${UNAME} \
    && mkdir /home/${UNAME} \
    && echo 'echo "___                                   "' >> /home/${UNAME}/.bashrc \
    && echo 'echo " |   _      _ |_      _   _ |_ |_     "' >> /home/${UNAME}/.bashrc \
    && echo 'echo " |  |  |_| _) |_ \)/ (_) |  |_ | ) \/ "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "                                   /  "' >> /home/${UNAME}/.bashrc \
    && echo 'echo " __                                   "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "(_      _ |_  _  _   _                "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "__) \/ _) |_ (- ||| _)                "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "    /                                 "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "Hello, welcome to the sel4/CAmkES/L4v docker build environment"' >> /home/${UNAME}/.bashrc \
    && echo 'export PATH=/scripts/repo:$PATH' >> /home/${UNAME}/.bashrc \
    && echo 'cd /host' >> /home/${UNAME}/.bashrc \
    && mkdir -p /isabelle \
    && chown -R ${UNAME}:${UNAME} /isabelle \
    && ln -s /isabelle /home/${UNAME}/.isabelle \
    && chown -R ${UNAME}:${UNAME} /home/${UNAME} \
    && chmod -R ug+rw /home/${UNAME} 

VOLUME /home/${UNAME}
VOLUME /isabelle
