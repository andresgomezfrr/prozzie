---
---

# Flow protocols
## Netflow
### Netflow using included f2k
In order to setup netflow in prozzie, you need to add all netflow probes to
NETFLOW_PROBES env variable, using the format described in
[f2k readme](https://github.com/wizzie-io/f2k/blob/master/README.md#sensors-config).
For example, executing linux setup this way:

```
NETFLOW_PROBES='{"sensors_networks":{"127.0.0.1":{"observations_id":{"default":{}}}}}' setups/f2k_setup.sh
```

To configure netflow probe, please use [f2k_setup.sh](../setups/f2k_setup.sh)
over a valid prozzie installation. You will be asked for the next questions:

NETFLOW_PROBES
:Netflow probes to expect netflow from, following the format described in
[f2k readme](https://github.com/wizzie-io/f2k/blob/master/README.md#sensors-config).

NETFLOW_COLLECTOR_PORT
:Port to listen for netflow traffic. It's 2055 by default.

NETFLOW_KAFKA_TOPIC
:Topic to produce netflow traffic. If you want flow treatment, it's better to
use the `flow` default.

### Netflow using nfacctd
You can use you pmacct nfacctd flow collector if you provide it with a config
file provided in [pmacctd](#pmacctd). You have to remember to use
`sfacctd_renormalize` instead of `pmacctd_renormalize`, and no interface.

## sflow
Sflow support is provided via [pmacct](http://www.pmacct.net/)
[sflow](http://www.sflow.org/) sfacctd accounting daemon. You can configure it
in prozzie using [sfacctd_setup.sh](../setups/sfacctd_setup.sh).

You will be asked about these variables:

SFLOW_KAFKA_TOPIC
:Topic to produce sflow traffic. Need to let it by default if you want proper
indexing.

SFLOW_COLLECTOR_PORT
:Ports to listen for sflow traffic.

SFLOW_RENORMALIZE
:Normalize sflow byte/packet counter based on sflow packet sampling rate. Check
the [pmacct Oficial Config Keys](http://wiki.pmacct.net/OfficialConfigKeys) for
more info.

SFLOW_AGGREGATE
:Fields/dimensions to send in each event. The more fields you send, the more
memory and CPU will sfacctd use.

In order to use your own sfacctd outside prozzie, you can configure it to send
to wizzie prozzie, following a configuration found in [pmacctd](#pmacctd), but
using `sfacctd_renormalize` instead of `pmacctd_renormalize`, and no interface.

## [pmacctd](http://www.pmacct.net/)
You can use your own pmacctd probe installation to avoid sflow/netflow
conversion. You only need to configure it to send to prozzie kafka, to sflow
topic:

```
interface: <interface to monitor>
sampling_rate: 1

plugins: kafka

timestamps_since_epoch: true
timestamps_secs: true

kafka_output: json
kafka_broker_host: <prozzie public IP address>
kafka_broker_port: 9092
kafka_topic: pmacct
pmacctd_renormalize: true
```
