---
---

# MQTT

To configure MQTT you can use `kcli` tool.

* mqtt.properties

```
name=mqtt
connector.class=com.evokly.kafka.connect.mqtt.MqttSourceConnector
tasks.max=1
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=org.apache.kafka.connect.storage.StringConverter

#Settings
kafka.topic=mqtt
mqtt.client_id=my-id
mqtt.clean_session=true
mqtt.connection_timeout=30
mqtt.keep_alive_interval=60
mqtt.server_uris=tcp://localhost:1883
mqtt.topic=mqtttopic/1
mqtt.qos=1
message_processor_class=com.evokly.kafka.connect.mqtt.sample.StringProcessor
```

You need to configure the mqtt.properties file with your properties:

mqtt.server_uris
: The MQTT brokers.

mqtt.topic
: The MQTT topics to subcribe.

kafka.topic
: The Kafka topic to send the messages.

When you configure the `mqtt.properties` you need to create the connector:

`kcli create mqtt-connector < mqtt.properties`
