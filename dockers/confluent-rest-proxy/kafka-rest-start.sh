#!/usr/bin/env bash
envsubst < /etc/kafka-rest/kafka-rest_env.properties > /etc/kafka-rest/kafka-rest.properties
/usr/bin/kafka-rest-start /etc/kafka-rest/kafka-rest.properties
