FROM ssrg_tools_gcc5

ENV BAMBOO_REMOTE_AGENT_URL http://bamboo.keg.ertos.in.nicta.com.au:8085/agentServer/agentInstaller/atlassian-bamboo-agent-installer-5.12.2.jar
ENV BAMBOO_SERVER_URL http://bamboo.keg.ertos.in.nicta.com.au:8085/agentServer
ENV JAVA_URL    http://download.oracle.com/otn-pub/java/jdk/8u65-b17
ENV JAVA_TAR    jdk-8u65-linux-x64.tar.gz
ENV JAVA_DIR	jdk1.8.0_65


# Install java
RUN cd /root \
    && wget --header "Cookie: oraclelicense=accept-securebackup-cookie" "${JAVA_URL}/${JAVA_TAR}" \
    && mkdir /opt/jdk 

RUN cd /opt/jdk \
    && tar -xf /root/${JAVA_TAR} \
    && rm /root/${JAVA_TAR} 

RUN update-alternatives --install /usr/bin/java java /opt/jdk/${JAVA_DIR}/bin/java 100 \
    && update-alternatives --install /usr/bin/javac javac /opt/jdk/${JAVA_DIR}/bin/javac 100 \
    && java -version


# Get the remote agent software
RUN cd \
    && wget -nv ${BAMBOO_REMOTE_AGENT_URL} 

RUN java -Dbamboo.home=/root/remote-agent -jar /root/atlassian-bamboo-agent-installer-5.12.2.jar ${BAMBOO_SERVER_URL} install

COPY res/bamboo-remote-agent.capabilities /root/remote-agent/bin/bamboo-capabilities.properties

WORKDIR /root

CMD ["java", "-Dbamboo.home=/root/remote-agent", "-jar", "/root/atlassian-bamboo-agent-installer-5.12.2.jar", "${BAMBOO_SERVER_URL}", "console"]

