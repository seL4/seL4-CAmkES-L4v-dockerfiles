FROM bamboo_base

ENV BAMBOO_VERSION       5.9.7
ENV BAMBOO_HOME          /var/atlassian/application-data/bamboo
ENV BAMBOO_INSTALL_DIR   /opt/atlassian/bamboo
ENV JAVA_URL    http://download.oracle.com/otn-pub/java/jdk/8u65-b17
ENV JAVA_TAR    jdk-8u65-linux-x64.tar.gz
ENV JAVA_DIR	jdk1.8.0_65

RUN wget -nv http://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz \
    && mv atlassian-bamboo-${BAMBOO_VERSION}.tar.gz /var/tmp/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz

COPY res/${JAVA_TAR} /
#RUN wget --header "Cookie: oraclelicense=accept-securebackup-cookie" \
#    "${JAVA_URL}/${JAVA_TAR}" \
RUN mkdir /opt/jdk \
    && tar -xf ${JAVA_TAR} -C /opt/jdk \
    && update-alternatives --install /usr/bin/java java /opt/jdk/${JAVA_DIR}/bin/java 100 \
    && update-alternatives --install /usr/bin/javac javac /opt/jdk/${JAVA_DIR}/bin/javac 100 \
    && java -version

RUN mkdir -p ${BAMBOO_INSTALL_DIR} \
    && mkdir -p ${BAMBOO_HOME} 

RUN tar -xf /var/tmp/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz --strip 1 -C ${BAMBOO_INSTALL_DIR}
RUN rm /${JAVA_TAR} \
    && rm /var/tmp/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz

RUN echo "bamboo.home= ${BAMBOO_HOME}" >> ${BAMBOO_INSTALL_DIR}/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties

RUN sed -i.bak s/JVM_MINIMUM_MEMORY=\"256m\"/JVM_MINIMUM_MEMORY=\"1024m\"/g /opt/atlassian/bamboo/bin/setenv.sh \
    && sed -i.bak s/JVM_MAXIMUM_MEMORY=\"384m\"/JVM_MAXIMUM_MEMORY=\"3072m\"/g /opt/atlassian/bamboo/bin/setenv.sh

COPY res/plugins/hung-build-killer-2.1.4.jar ${BAMBOO_INSTALL_DIR}/atlassian-bamboo/WEB-INF/lib/hung-build-killer-2.1.4.jar
COPY res/plugins/coverage-report-1.0-SNAPSHOT.jar ${BAMBOO_INSTALL_DIR}/atlassian-bamboo/WEB-INF/lib/coverage-report-1.0-SNAPSHOT.jar
 
VOLUME ["${BAMBOO_HOME}"]

# HTTP port
EXPOSE 8085

RUN echo '#!/bin/bash' | cat - /opt/atlassian/bamboo/bin/start-bamboo.sh > /tmp/out \
    && cat /tmp/out > /opt/atlassian/bamboo/bin/start-bamboo.sh 

CMD ["/opt/atlassian/bamboo/bin/start-bamboo.sh", "-fg"]

