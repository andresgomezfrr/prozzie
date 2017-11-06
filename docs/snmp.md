# SNMP prozzie support
## SNMP polling
In order to setup SNMP polling in prozzie, is advisable to add all snmp agents
to `MONITOR_SENSORS_ARRAY` environment variable before use monitor setup, using
the format described in
[monitor readme](https://github.com/wizzie-io/monitor#simple-snmp-monitoring).
For example, executing monitor setup this way:

```
MONITOR_SENSORS_ARRAY='{"sensor_id":1,"timeout":2000,"sensor_name": "my-sensor","sensor_ip": "172.18.0.1","snmp_version":"2c","community" : "public","monitors": [{"name": "mem_total", "oid": "HOST-RESOURCES-MIB::hrMemorySize.0", "unit": "%"}]}' setups/monitor_setup.sh
```
