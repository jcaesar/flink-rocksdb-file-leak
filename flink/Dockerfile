FROM flink:1.8.1-scala_2.11

RUN wget --progress=dot:mega -P /opt/flink/lib/ https://repo.maven.apache.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/2.8.3-7.0/flink-shaded-hadoop-2-uber-2.8.3-7.0.jar
# hadolint ignore=DL4006
RUN echo "4ea4e9c401afdd34ef33dc26f679c558487a3999 /opt/flink/lib/flink-shaded-hadoop-2-uber-2.8.3-7.0.jar" | sha1sum -c
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
