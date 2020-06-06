ARG EXTRAS_IMG=extras
FROM $EXTRAS_IMG

# Get user UID and username
ARG UID
ARG UNAME
ARG GID
ARG GROUP

# Crammed a lot in here to make building the image faster
RUN groupadd -fg ${GID} ${GROUP} \
    && useradd -u ${UID} -g ${GID} ${UNAME} \
    && adduser ${UNAME} sudo \
    && passwd -d ${UNAME} \
    && echo 'Defaults        lecture_file = /etc/sudoers.lecture' >> /etc/sudoers \
    && echo 'Defaults        lecture = always' >> /etc/sudoers \
    && echo '##################### Warning! #####################################' > /etc/sudoers.lecture \
    && echo 'This is an ephemeral docker container! You can do things to it using' >> /etc/sudoers.lecture \
    && echo 'sudo, but when you exit, changes made outside of the /host directory' >> /etc/sudoers.lecture \
    && echo 'will be lost.' >> /etc/sudoers.lecture \
    && echo 'If you want your changes to be permanent, add them to the ' >> /etc/sudoers.lecture \
    && echo '    extras.dockerfile' >> /etc/sudoers.lecture \
    && echo 'in the seL4-CAmkES-L4v dockerfiles repo.' >> /etc/sudoers.lecture \
    && echo '####################################################################' >> /etc/sudoers.lecture \
    && echo '' >> /etc/sudoers.lecture \
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
    && chown -R ${UNAME}:${GROUP} /isabelle \
    && ln -s /isabelle /home/${UNAME}/.isabelle \
    && chown -R ${UNAME}:${GROUP} /home/${UNAME} \
    && chmod -R ug+rw /home/${UNAME} 

VOLUME /home/${UNAME}
VOLUME /isabelle
