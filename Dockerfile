FROM parana/centos7

# Based on centos:7.2.1511 Public Image

MAINTAINER "João Antonio Ferreira" <joao.parana@gmail.com>`

ENV REFRESHED_AT 2016-06-30

# Adding Apache web server
RUN yum -y update && yum -y install httpd && yum clean all && systemctl enable httpd.service
# RUN yum -y install httpd && yum clean all && systemctl enable httpd.service
EXPOSE 80

# Adding Oracle Install from oracle.com
ADD rpm/* /tmp/
# File was splited using: split -b 49000000 oracle-xe-11.2.0-1.0.x86_64.rpm
RUN cd /tmp && cat xaa xab xac xad xae xaf xag > oracle-xe-11.2.0-1.0.x86_64.rpm && rm -rf xaa xab xac xad xae xaf xag

# Pre-requirements
RUN mkdir -p /run/lock/subsys

RUN yum install -y libaio bc initscripts net-tools
 
# Install Oracle XE
RUN yum localinstall -y /tmp/oracle-xe-11.2.0-1.0.x86_64.rpm && \
    rm -rf /tmp/oracle-xe-11.2.0-1.0.x86_64.rpm
 
# Configure instance
ADD config/xe.rsp config/init.ora config/initXETemp.ora /u01/app/oracle/product/11.2.0/xe/config/scripts/
RUN chown oracle:dba /u01/app/oracle/product/11.2.0/xe/config/scripts/*.ora \
                     /u01/app/oracle/product/11.2.0/xe/config/scripts/xe.rsp
RUN chmod 755        /u01/app/oracle/product/11.2.0/xe/config/scripts/*.ora \
                     /u01/app/oracle/product/11.2.0/xe/config/scripts/xe.rsp
ENV ORACLE_HOME /u01/app/oracle/product/11.2.0/xe
ENV ORACLE_SID  XE
ENV PATH        $ORACLE_HOME/bin:$PATH

RUN echo "••••" && cat /u01/app/oracle/product/11.2.0/xe/config/scripts/xe.rsp && echo "••••"
RUN /etc/init.d/oracle-xe configure responseFile=/u01/app/oracle/product/11.2.0/xe/config/scripts/xe.rsp

# Run script
ADD config/start.sh /

EXPOSE 1521
EXPOSE 8087

# Java Version
ENV JAVA_VERSION_MAJOR 8
ENV JAVA_VERSION_MINOR 66
ENV JAVA_VERSION_BUILD 17
ENV JAVA_PACKAGE       jdk

# Download and unarchive Java
RUN curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" \
  http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
    | tar -xzf - -C /opt && \
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

# Set environment
ENV JAVA_HOME /opt/jdk

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH ${PATH}:${JAVA_HOME}/bin:${CATALINA_HOME}/bin:${CATALINA_HOME}/scripts

ENV TOMCAT_MAJOR_VERSION 8
ENV TOMCAT_VERSION 8.0.36
ENV TOMCAT_SITE http://archive.apache.org/dist/tomcat
ENV TOMCAT_TGZ_URL ${TOMCAT_SITE}/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

ENV JAVA_OPTS="-Xms512m -Xmx1024m"

# Create tomcat user
RUN groupadd -r tomcat && \
	useradd -g tomcat -d ${CATALINA_HOME} -s /sbin/nologin  -c "Tomcat user" tomcat && \
	chown -R tomcat:tomcat ${CATALINA_HOME}

RUN mkdir -p /usr/local/tomcat  && chown tomcat:tomcat /usr/local/tomcat

USER tomcat
WORKDIR /tmp
# http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz
RUN curl -O http://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz && tar -xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz && mv apache-tomcat-${TOMCAT_VERSION}/* /usr/local/tomcat && ls -la /usr/local/tomcat && rm -rf apache-tomcat*

RUN echo "Conteúdo do diretorio /etc e /etc/systemd " ; ls -lat /etc ; ls -lat /etc/systemd ;  ls -lat /etc/systemd/system/

EXPOSE 8080

ADD config/tomcat.service /etc/systemd/system/tomcat.service
RUN ls -lat /etc/systemd/system/

USER root
RUN systemctl enable tomcat

RUN yum clean all

CMD /start.sh

# CMD ["/usr/sbin/init"]

