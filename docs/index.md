---
---
# Prozzie

[Prozzie](http://github.com/wizzie-io/prozzie) is the main entry point for the
data plane of [Wizzie Data Platform](http://wizzie.io/).

Under the hoods, prozzie is just a docker-compose file that provides you the
basics for sending the data events to WDP: authentication, encryption,
homogenization and a flexible kafka buffer for back-pressure and local data
persistence.

It provides out-of-the-box support for **json** over kafka, http POSTs, and
mqtt, and it supports others such as netflow, snmp, and json over mqtt with a
small configuration.

Please navigate through the different sections to know how to
[Install](installation/Installation) or configure prozzie.
