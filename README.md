# prozzie

The prozzie works using docker-compose. The prozzie allows us to send data to Wizzie Cloud. It does the authentication, back-pressure, data encryption and data persistent.

### Installation

1. Clone

  ```
  git clone https://github.com/wizzie-io/prozzie.git
  ```

2. Install docker-compose

  * https://docs.docker.com/compose/install/

3. Configure the ${INTERFACE_IP} and ${CLIENT_API_KEY} ENV var inside `.env` 

4. Execute the prozzie

   ```
   docker-compose up
   ```

To start and stop the prozzie, you can use:

  * start

  ```
  docker-compose start
  ```

  * stop

  ```
  docker-compose stop
  ```

If you want remove the prozzie, you can execute:

   ```
   docker-compose down
   ```

### Docker Components

Currently, the prozzie has multiple services to run:

 - [Zookeeper](https://hub.docker.com/_/zookeeper/)
 - [Kafka](https://hub.docker.com/r/wurstmeister/kafka/)
 - [Confluent Rest Proxy](https://github.com/wizzie-io/prozzie/tree/master/dockers/confluent-rest-proxy/)

### Supported Protocols

- [x] Kafka
- [x] [JSON over HTTP](http://docs.confluent.io/3.0.0/kafka-rest/docs/intro.html#produce-and-consume-json-messages)
- [x] [Avro over HTTP](http://docs.confluent.io/3.0.0/kafka-rest/docs/intro.html#produce-and-consume-avro-messages)
- [x] [Binary over HTTP](http://docs.confluent.io/3.0.0/kafka-rest/docs/intro.html#produce-and-consume-binary-messages)
