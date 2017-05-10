FROM ubuntu:16.04

RUN apt-get -y update && apt-get install -y wget software-properties-common
RUN wget -qO - http://packages.confluent.io/deb/3.2/archive.key | apt-key add -
RUN add-apt-repository "deb [arch=amd64] http://packages.confluent.io/deb/3.2 stable main"
RUN apt-get -y update && apt-get install -y confluent-kafka-rest=3.2.1-1
RUN apt-get install -y openjdk-8-jre gettext-base

RUN rm -f /etc/kafka-rest/kafka-rest.properties
ADD kafka-rest_env.properties /etc/kafka-rest/kafka-rest_env.properties
ADD kafka-rest-start.sh /usr/bin/kafka-rest-start.sh

ENV CONSUMER_THREADS 1
ENV PRODUCER_THREADS 1

CMD ["kafka-rest-start.sh", "/etc/kafka-rest/kafka-rest.properties"]
