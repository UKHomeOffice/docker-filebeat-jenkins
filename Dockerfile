FROM quay.io/ukhomeofficedigital/centos-base:v0.5.0

RUN yum install -y curl && yum clean all && rpm --rebuilddb

ENV FILEBEAT_VERSION=5.3.0 \
    JENKINS_INSTANCE=jenkins \
    FILEBEAT_SHA1=c6f56d1a938889ec9f5db7caea266597f625fcc1 \
    ELASTICSEARCH_HOST=localhost \
    ELASTICSEARCH_PORT=9200 \
    ELASTICSEARCH_INDEX=jenkins-filebeat-%{+yyyy.MM.dd}

RUN set -x && \
  yum update && \
  yum install -y wget && \
  wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-linux-x86_64.tar.gz -O /opt/filebeat.tar.gz && \
  cd /opt && \
  echo "${FILEBEAT_SHA1}  filebeat.tar.gz" | sha1sum -c - && \
  tar xzvf filebeat.tar.gz && \
  cd filebeat-* && \
  cp filebeat /bin && \
  cd /opt && \
  rm -rf filebeat* && \
  yum remove -y wget && \
  yum clean all && rm -rf /tmp/* /var/tmp/*

COPY ./config docker-entrypoint.sh /
RUN chmod go-w /filebeat.yml

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [ "filebeat", "-e" ]
