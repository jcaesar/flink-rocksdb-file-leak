# Don't build in docker. This is for debugging purposes, so you want to do incremental builds…
#FROM maven:3.5.4-jdk-8-alpine as builder
#
#RUN apk add python3
#RUN /usr/sbin/adduser -h /flinkbuild -D flinkbuild
#WORKDIR /flink
#COPY configuremavenproxy /usr/bin/
#
#COPY flink-src /flink
#RUN chown -R flinkbuild:flinkbuild /flink /flinkbuild
#USER flinkbuild
#ARG https_proxy
#ARG mavensonatypenexus
#RUN mkdir ~/.m2 && configuremavenproxy >~/.m2/settings.xml
#
#RUN mvn -B package -DskipTests -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Drat.skip=true -T$(nproc)

# TODO: This is a modified copy of https://github.com/docker-flink/docker-flink/blob/master/1.5/hadoop28-scala_2.11-debian/Dockerfile so license… humm.
FROM openjdk:8-jre

# Install dependencies
RUN set -ex; \
  apt-get update; \
  apt-get -y install \
    dnsutils \
    gosu \
    jq \
    libsnappy1v5 \
    maven \
    netcat-traditional \
    openjdk-8-jdk-headless \
    python3 \
    wget \
  ; \
  rm -rf /var/lib/apt/lists/*

# Configure Flink version
ENV FLINK_VERSION=1.8.1 \
    HADOOP_SCALA_VARIANT=hadoop28-scala_2.11

# Prepare environment
ENV FLINK_HOME=/opt/flink
ENV PATH=$FLINK_HOME/bin:$PATH
RUN groupadd --system --gid=9999 flink && \
    useradd --system --home-dir $FLINK_HOME --uid=9999 --gid=flink flink
WORKDIR $FLINK_HOME

# Install Flink
#COPY --from=builder /flink/flink-dist/target/flink-$FLINK_VERSION-bin/flink-$FLINK_VERSION/ $FLINK_HOME
COPY flink-src $FLINK_HOME
RUN chown -R flink:flink .

RUN wget --progress=dot:mega -P /opt/flink/lib/ https://repo.maven.apache.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/2.8.3-7.0/flink-shaded-hadoop-2-uber-2.8.3-7.0.jar
# hadolint ignore=DL4006
RUN echo "4ea4e9c401afdd34ef33dc26f679c558487a3999 /opt/flink/lib/flink-shaded-hadoop-2-uber-2.8.3-7.0.jar" | sha1sum -c

# Configure container
COPY --from=library/flink:1.8.1-scala_2.11 /docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 6123 8081
CMD ["help"]

COPY flink-conf.yaml zoo.cfg /opt/flink/conf/
COPY hadoop /opt/flink/hadoop

#RUN cp /opt/flink/opt/flink-metrics-prometheus-1.8.0.jar /opt/flink/lib
RUN chmod 777 /media
# hadolint ignore=SC2028
RUN echo >>conf/log4j-console.properties " \
	\nlog4j.logger.org.apache.flink.runtime.state.DefaultOperatorStateBackend=WARN, console \
	\nlog4j.logger.org.apache.flink.contrib.streaming.state.RocksDBKeyedStateBackend=TRACE, console \
	\nlog4j.logger.org.apache.flink.contrib.streaming.state.RocksDBIncrementalSnapshotStrategy=TRACE, console \
	\nlog4j.logger.org.apache.flink.contrib.streaming.state=TRACE, console \
	\nlog4j.logger.org.apache.flink.runtime.rest.handler.job.JobDetailsHandler=OFF \
"
