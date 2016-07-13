FROM parana/centos7

# Based on centos:7.2.1511 Public Image

MAINTAINER "João Antonio Ferreira" <joao.parana@gmail.com>`

ENV REFRESHED_AT 2016-07-05-16-30hours

#
# Please execute cd install && ./get-java8-and-tomcat8 to Download binary files if you prefer
#

# Adding Oracle and others dependencies
RUN yum install -y libaio bc initscripts net-tools rsyslog && yum clean all

# Set environment
ENV JAVA_HOME /opt/jdk

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH ${PATH}:${JAVA_HOME}/bin:${CATALINA_HOME}/bin:${CATALINA_HOME}/scripts

ENV TOMCAT_MAJOR_VERSION 8
ENV TOMCAT_VERSION 8.0.36
ENV TOMCAT_SITE    http://archive.apache.org/dist/tomcat
ENV TOMCAT_TGZ_URL ${TOMCAT_SITE}/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
ENV TOMCAT_FILE    apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Java Version
ENV JAVA_VERSION_MAJOR 8
ENV JAVA_VERSION_MINOR 66
ENV JAVA_VERSION_BUILD 17
ENV JAVA_PACKAGE       jdk
ENV ORACLE_SITE        download.oracle.com/otn-pub/java/jdk
ENV JAVA_FILE          ${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz

ENV JAVA_OPTS="-Xms512m -Xmx1024m"

ENV ORACLE_HOME /u01/app/oracle/product/11.2.0/xe
ENV ORACLE_SID  XE
ENV PATH        $ORACLE_HOME/bin:$PATH

# This Files must be copied
# install/tomcat8/apache-tomcat-8.0.36.tar.gz
# install/jdk8/xaa
# install/jdk8/xab
# install/jdk8/xac
# install/jdk8/xad
# install/oracle-xe-11-2-0/response/xe.rsp
# install/oracle-xe-11-2-0/upgrade/gen_inst.sql
# install/oracle-xe-11-2-0/xaa
# install/oracle-xe-11-2-0/xab
# install/oracle-xe-11-2-0/xac
# install/oracle-xe-11-2-0/xad
# install/oracle-xe-11-2-0/xae
# install/oracle-xe-11-2-0/xaf
# install/oracle-xe-11-2-0/xag

# Adding Oracle Install from oracle.com
# RUN rm -rf /tmp/* 
COPY install /tmp/
RUN find /tmp -type d | sort 
#### apache-tomcat-8.0.36.tar.gz get-java8-and-tomcat8       jdk8                        oracle-xe-11-2-0
# File was splited using: split -b 49000000 oracle-xe-11.2.0-1.0.x86_64.rpm
RUN cd /tmp/oracle-xe-11-2-0 && cat xaa xab xac xad xae xaf xag > /tmp/oracle-xe-11.2.0-1.0.x86_64.rpm && rm -rf xaa xab xac xad xae xaf xag 
RUN echo "Generating ${JAVA_FILE}" && cd /tmp/jdk8 && cat xaa xab xac xad > /tmp/${JAVA_FILE} && rm -rf xaa xab xac xad 

# Pre-requirements
RUN mkdir -p /run/lock/subsys

# Install Oracle XE
RUN yum localinstall -y /tmp/oracle-xe-11.2.0-1.0.x86_64.rpm && \
    rm -rf /tmp/oracle-xe-11.2.0-1.0.x86_64.rpm
 
# Configure instance
ADD config/xe.rsp config/init.ora config/initXETemp.ora /u01/app/oracle/product/11.2.0/xe/config/scripts/
RUN chown oracle:dba /u01/app/oracle/product/11.2.0/xe/config/scripts/*.ora \
                     /u01/app/oracle/product/11.2.0/xe/config/scripts/xe.rsp
RUN chmod 755        /u01/app/oracle/product/11.2.0/xe/config/scripts/*.ora \
                     /u01/app/oracle/product/11.2.0/xe/config/scripts/xe.rsp

RUN echo "••••" && cat /u01/app/oracle/product/11.2.0/xe/config/scripts/xe.rsp && echo "••••"
RUN /etc/init.d/oracle-xe configure responseFile=/u01/app/oracle/product/11.2.0/xe/config/scripts/xe.rsp

EXPOSE 1521
EXPOSE 8087

# unarchive Java
RUN cat /tmp/${JAVA_FILE} | tar -xzf - -C /opt && \
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
    rm -rf /opt/jdk/*src.zip \
           /opt/jdk/lib/missioncontrol \
           /opt/jdk/lib/visualvm \
           /opt/jdk/lib/*javafx* \
           /opt/jdk/jre/lib/plugin.jar \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/plugin \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so


# Create tomcat user
RUN groupadd -r tomcat && \
	useradd -g tomcat -d ${CATALINA_HOME} -s /sbin/nologin  -c "Tomcat user" tomcat && \
	chown -R tomcat:tomcat ${CATALINA_HOME}

RUN mkdir -p /usr/local/tomcat  && chown tomcat:tomcat /usr/local/tomcat

USER tomcat
WORKDIR /tmp
# http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz
RUN tar -xzf tomcat8/${TOMCAT_FILE} && mv apache-tomcat-${TOMCAT_VERSION}/* /usr/local/tomcat && ls -la /usr/local/tomcat && rm -rf apache-tomcat*

RUN echo "Conteúdo do diretorio /etc e /etc/systemd " ; ls -lat /etc ; ls -lat /etc/systemd ;  ls -lat /etc/systemd/system/

EXPOSE 8080

ADD config/tomcat.service /etc/systemd/system/tomcat.service
RUN ls -lat /etc/systemd/system/

USER root
RUN systemctl enable tomcat

# Run script
ADD config/start.sh /start-all.sh
CMD /start-all.sh

# CMD ["/usr/sbin/init"]

