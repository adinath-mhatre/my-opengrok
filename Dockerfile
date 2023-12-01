FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y \
    build-essential \
    git \
    autoconf \
    automake \
    pkg-config \
    python3 \
    python3-venv \
    default-jre \
    default-jdk \
    ufw

RUN mkdir /workdir
WORKDIR /workdir

RUN git clone https://github.com/universal-ctags/ctags.git
WORKDIR /workdir/ctags
RUN ./autogen.sh
RUN ./configure
RUN make
RUN make install

WORKDIR /workdir
RUN apt-get install -y wget
RUN wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.16/bin/apache-tomcat-10.1.16.tar.gz

RUN useradd -m -d /opt/tomcat -U -s /bin/false tomcat
RUN tar xzvf apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1
RUN chown -R tomcat:tomcat /opt/tomcat/
RUN chmod -R u+x /opt/tomcat/bin

COPY files /workdir/files
RUN mv /workdir/files/tomcat-users.xml /opt/tomcat/conf/tomcat-users.xml
RUN mv /workdir/files/manager_META-INF_context.xml /opt/tomcat/webapps/manager/META-INF/context.xml
RUN mv /workdir/files/host-manager_META-INF_context.xml /opt/tomcat/webapps/host-manager/META-INF/context.xml

ENV JAVA_HOME /usr/lib/jvm/java-1.11.0-openjdk-amd64
ENV JAVA_OPTS -Djava.security.egd=file:///dev/urandom
ENV CATALINA_BASE /opt/tomcat
ENV CATALINA_HOME /opt/tomcat
ENV CATALINA_PID /opt/tomcat/temp/tomcat.pid
ENV CATALINA_OPTS -Xms512M -Xmx1024M -server -XX:+UseParallelGC

RUN mkdir /opengrok
WORKDIR /opengrok
RUN mkdir src data dist etc log

WORKDIR /workdir
RUN wget https://github.com/oracle/opengrok/releases/download/1.12.23/opengrok-1.12.23.tar.gz
RUN tar -C /opengrok/dist --strip-components=1 -xzf opengrok-1.12.23.tar.gz
RUN mv /workdir/files/opengrok-logging.properties /opengrok/etc/logging.properties
RUN mv /workdir/files/readonly-configuration.xml /opengrok/etc

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /opengrok/dist/tools
RUN python3 -m pip install opengrok-tools.tar.gz
RUN opengrok-deploy -c /opengrok/etc/configuration.xml /opengrok/dist/lib/source.war /opt/tomcat/webapps
RUN opengrok-deploy -i /workdir/files/insert.xml /opengrok/dist/lib/source.war /opt/tomcat/webapps/source.war

WORKDIR /opengrok/src
RUN git clone https://github.com/githubtraining/hellogitworld.git

RUN mkdir foo bar
RUN echo greenparrot > foo/data.txt
RUN echo greenparrot > bar/data.txt

RUN echo foo > /opengrok/etc/foo-whitelist.txt
RUN echo root >> /opengrok/etc/foo-whitelist.txt
RUN echo bar > /opengrok/etc/bar-whitelist.txt
RUN echo root >> /opengrok/etc/bar-whitelist.txt

RUN apt-get install -y vim
WORKDIR /workdir
EXPOSE 8080
RUN chmod +x /workdir/files/start.py
CMD ["/workdir/files/start.py"]
