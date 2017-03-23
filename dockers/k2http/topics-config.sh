#!/bin/sh
echo
for topic in $KAFKA_TOPICS; do
	echo "    - $topic"
done
