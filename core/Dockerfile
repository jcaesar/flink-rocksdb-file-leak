# Beware that this dockerfile is made to be run from the parent directory.
FROM maven:3.5.3-jdk-8 as build

COPY ./core/configuremavenproxy ./core/pom.xml /core/

WORKDIR /core
ARG http_proxy
ARG https_proxy
RUN mkdir ~/.m2 && ./configuremavenproxy >~/.m2/settings.xml
RUN  true \
	&& mkdir -p src/test/java \
	&& echo 'public class DummyTest { @org.junit.Test public void dumm() { org.junit.Assert.assertTrue(true); } }' >> src/test/java/DummyTest.java \
	&& mvn -B -Dcheckstyle.skip -Dmaven.javadoc.skip=true clean package \
	&& rm src/test/java/DummyTest.java
RUN rm -rf src
COPY ./core/src/ ./src
RUN mvn -B -Dcheckstyle.skip -Dmaven.javadoc.skip=true clean package
RUN mv target/file-leak-*.jar /core/job.jar

FROM scratch as install
COPY ./flink/common /common
COPY ./flink/flink-runscript /flink-runscript
COPY ./core/runscript /
COPY --from=build /core/job.jar /

FROM flink:1.8.0-scala_2.11
RUN apt-get update && apt-get -y install --no-install-recommends kafkacat dnsutils netcat-traditional jq wget vim && rm -rf /lib/dpkg

RUN mkdir /job && chown flink:flink /job
USER flink

WORKDIR /job/
ENTRYPOINT ["./runscript"]

COPY --from=install / /job
