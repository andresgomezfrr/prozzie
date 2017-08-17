# prozzie

The prozzie works using docker-compose. The prozzie allows us to send data to Wizzie Cloud. It does the authentication, back-pressure, data encryption and data persistence.

## Installation

### Automatic Installation

Use the setup script that is inside the setup folder.

### Manual Installation

1. Clone

  ```
  git clone https://github.com/wizzie-io/prozzie.git
  ```

2. Install docker-compose

  * https://docs.docker.com/compose/install/

3. You can configure the parameters into `.env` file:
    * INTERFACE_IP
    * CLIENT_API_KEY
    * ZZ_HTTP_ENDPOINT

    To see a list of all variables, please refer to
    [Variables table](VARIABLES.md)

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

## Docker Components

Currently, the prozzie has multiple services to run:

 - [Zookeeper 3.4.10](https://hub.docker.com/_/zookeeper/)
 - [Kafka 0.10.2.0](https://hub.docker.com/r/wurstmeister/kafka/)
 - [K2http 1.3.0](https://github.com/wizzie-io/k2http)
 - [Wizzie Kafka Connect 0.0.1](https://github.com/wizzie-io/kafka-connect-docker)
 - [Confluent Rest Proxy 3.2.1](https://github.com/wizzie-io/prozzie/tree/master/dockers/confluent-rest-proxy/)

## Supported Protocols

- [x] Kafka
- [x] [JSON over HTTP](http://docs.confluent.io/3.0.0/kafka-rest/docs/intro.html#produce-and-consume-json-messages)
- [x] [Avro over HTTP](http://docs.confluent.io/3.0.0/kafka-rest/docs/intro.html#produce-and-consume-avro-messages)
- [x] [Binary over HTTP](http://docs.confluent.io/3.0.0/kafka-rest/docs/intro.html#produce-and-consume-binary-messages)
- [x] [Syslog: UDP, TCP, SSL](https://github.com/jcustenborder/kafka-connect-syslog)
- [x] [MQTT](https://github.com/evokly/kafka-connect-mqtt)
- [x] [Netflow](https://github.com/wizzie-io/f2k)
- [x] sFlow (via [pmacct](http://www.pmacct.net/))
- [ ] SNMP

## Netflow
In order to setup netflow in prozzie, you need to add all netflow probes to
NETFLOW_PROBES env variable, using the format described in
[f2k readme](https://github.com/wizzie-io/f2k/blob/master/README.md#sensors-config).
For example, executing linux setup this way:

```
NETFLOW_PROBES='{"sensors_networks":{"127.0.0.1":{"observations_id":{"default":{}}}}}' setups/f2k_setup.sh
```

To configure netflow probe, please use (f2k_setup.sh)[setups/f2k_setup.sh] over
a valid prozzie installation.

## sflow
Sflow support is provided via [pmacct](http://www.pmacct.net/)
[sflow](http://www.sflow.org/) sfacctd accounting daemon. You can configure it
in prozzie using (sfacctd_setup.sh)[setups/sfacctd_setup.sh].

## Tools
 * **prozzie-start**: Start prozzie script.
 * **prozzie-stop**: Stop prozzie script.
 * **kcli**: CLI to work with Kafka Connect. Usage: `kcli --help`
