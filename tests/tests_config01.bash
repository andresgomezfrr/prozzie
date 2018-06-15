#!/usr/bin/env bash

declare -r PROZZIE_PREFIX=/opt/prozzie
declare -r INTERFACE_IP="a.b.c.d"

. backupconfig.sh
. base_tests_config.bash

#--------------------------------------------------------
# TEST PROZZIE CONFIG OPTIONS
#--------------------------------------------------------

testBasicHelp() {
    # prozzie config must show help with no failure
    "${PROZZIE_PREFIX}"/bin/prozzie config
}

testConfigCommandHelp() {
    # prozzie config --help must show help with no failure
    "${PROZZIE_PREFIX}"/bin/prozzie config --help
}

testDescribeAll() {
    # prozzie config --describe-all must describe all modules with no failure
    "${PROZZIE_PREFIX}"/bin/prozzie config --describe-all
}

#--------------------------------------------------------
# TEST MODULES VARIABLES AND DESCRIPTIONS
#--------------------------------------------------------

testBaseModule() {
    genericTestModule 3 base ZZ_HTTP_ENDPOINT INTERFACE_IP CLIENT_API_KEY
}

testF2kModule() {
    genericTestModule 2 f2k NETFLOW_PROBES NETFLOW_KAFKA_TOPIC
}

testMonitorModule() {
    genericTestModule 4 monitor MONITOR_CUSTOM_MIB_PATH MONITOR_KAFKA_TOPIC \
        MONITOR_REQUEST_TIMEOUT MONITOR_SENSORS_ARRAY
}

testMqttModule() {
    genericTestModule 14 mqtt mqtt.server_uris kafka.topic mqtt.topic name \
        connector.class tasks.max key.converter value.converter mqtt.client_id \
        mqtt.clean_session mqtt.connection_timeout mqtt.keep_alive_interval \
        mqtt.qosl message_processor_class
}

testSyslogModule() {
    genericTestModule 11 syslog name connector.class tasks.max key.converter \
        value.converter key.converter.schemas.enable \
        value.converter.schemas.enable kafka.topic syslog.host syslog.port \
        syslog.structured.data
}

testSfacctdModule() {
    genericTestModule 3 sfacctd SFLOW_KAFKA_TOPIC SFLOW_RENORMALIZE \
        SFLOW_AGGREGATE
}

#--------------------------------------------------------
# TEST BASE MODULE
#--------------------------------------------------------

testSetupBaseModuleVariables() {
    # Try to change via setup
    genericSetupQuestionAnswer base \
        'Data HTTPS endpoint URL (use http://.. for plain HTTP)' \
            'my.test.endpoint' \
        "Interface IP address" \
            "${INTERFACE_IP}" \
        'Client API key' \
            'myApiKey'

    ${_ASSERT_TRUE_} '"prozzie config -s base must done with no failure"' $?

    genericTestModule 3 base 'ZZ_HTTP_ENDPOINT=https://my.test.endpoint/v1/data' \
                             "INTERFACE_IP=${INTERFACE_IP}" \
                             'CLIENT_API_KEY=myApiKey'
}

testSetBaseModuleVariables() {
    "${PROZZIE_PREFIX}"/bin/prozzie config base ZZ_HTTP_ENDPOINT my.super.test.endpoint
    "${PROZZIE_PREFIX}"/bin/prozzie config base INTERFACE_IP ${INTERFACE_IP}
    "${PROZZIE_PREFIX}"/bin/prozzie config base CLIENT_API_KEY mySuperApiKey

    genericTestModule 3 base 'ZZ_HTTP_ENDPOINT=https://my.super.test.endpoint/v1/data' \
                             "INTERFACE_IP=${INTERFACE_IP}" \
                             'CLIENT_API_KEY=mySuperApiKey'
}

#--------------------------------------------------------
# TEST F2K MODULE
#--------------------------------------------------------

testSetupF2kModuleVariables() {
    genericSetupQuestionAnswer f2k \
        "JSON object of NF probes (It's recommend to use env var)" \
            '\{\}' \
        'Topic to produce netflow traffic?' \
            'flow'

    genericTestModule 2 f2k 'NETFLOW_KAFKA_TOPIC=flow' \
                            'NETFLOW_PROBES={}'

    "${PROZZIE_PREFIX}"/bin/prozzie config f2k NETFLOW_PROBES '{"keyA":"valueA","keyB":"valueB"}'
    "${PROZZIE_PREFIX}"/bin/prozzie config f2k NETFLOW_KAFKA_TOPIC myFlowTopic

    genericTestModule 2 f2k  'NETFLOW_PROBES={"keyA":"valueA","keyB":"valueB"}' \
                             'NETFLOW_KAFKA_TOPIC=myFlowTopic'
}

#--------------------------------------------------------
# TEST MONITOR MODULE
#--------------------------------------------------------

testSetupMonitorModuleVariables() {
    declare mibs_directory mibs_directory2
    mibs_directory=$(mktemp -d)
    mibs_directory2=$(mktemp -d)
    declare -r mibs_directory mibs_directory2

    genericSetupQuestionAnswer monitor \
       'monitor custom mibs path (use monitor_custom_mibs for no custom mibs)' \
         "${mibs_directory}" \
       'Topic to produce monitor metrics' 'monitor' \
       'Seconds between monitor polling' '25' \
       'Monitor agents array' "\\'\\'"

    genericTestModule 4 monitor "MONITOR_CUSTOM_MIB_PATH=${mibs_directory}" \
                                'MONITOR_KAFKA_TOPIC=monitor' \
                                'MONITOR_REQUEST_TIMEOUT=25' \
                                "MONITOR_SENSORS_ARRAY=''"

    "${PROZZIE_PREFIX}"/bin/prozzie config monitor MONITOR_CUSTOM_MIB_PATH "${mibs_directory2}"
    "${PROZZIE_PREFIX}"/bin/prozzie config monitor MONITOR_KAFKA_TOPIC myMonitorTopic
    "${PROZZIE_PREFIX}"/bin/prozzie config monitor MONITOR_REQUEST_TIMEOUT 60
    "${PROZZIE_PREFIX}"/bin/prozzie config monitor MONITOR_SENSORS_ARRAY "'a,b,c,d'"

    genericTestModule 4 monitor "MONITOR_CUSTOM_MIB_PATH=${mibs_directory2}" \
                                'MONITOR_KAFKA_TOPIC=myMonitorTopic' \
                                'MONITOR_REQUEST_TIMEOUT=60' \
                                "MONITOR_SENSORS_ARRAY='a,b,c,d'"
}

#--------------------------------------------------------
# TEST SFACCTD MODULE
#--------------------------------------------------------

testSetupSfacctdModuleVariables() {
    genericSetupQuestionAnswer sfacctd \
         'sfacctd aggregation fields' 'a,b,c,d' \
         'Topic to produce sflow traffic' 'pmacct' \
         'Normalize sflow based on sampling' 'true'

    genericTestModule 3 sfacctd 'SFLOW_AGGREGATE=a,b,c,d' \
                                'SFLOW_KAFKA_TOPIC=pmacct' \
                                'SFLOW_RENORMALIZE=true'

    "${PROZZIE_PREFIX}"/bin/prozzie config sfacctd SFLOW_AGGREGATE "a,b,c,d,e,f,g,h"
    "${PROZZIE_PREFIX}"/bin/prozzie config sfacctd SFLOW_KAFKA_TOPIC mySflowTopic
    "${PROZZIE_PREFIX}"/bin/prozzie config sfacctd SFLOW_RENORMALIZE false

    genericTestModule 3 sfacctd 'SFLOW_AGGREGATE=a,b,c,d,e,f,g,h' \
                                'SFLOW_KAFKA_TOPIC=mySflowTopic' \
                                'SFLOW_RENORMALIZE=false'
}

#--------------------------------------------------------
# TEST MQTT MODULE
#--------------------------------------------------------

testSetupMqttModuleVariables() {
    genericSetupQuestionAnswer mqtt \
         'MQTT Topics to consume' '/my/mqtt/topic' \
         "Kafka's topic to produce MQTT consumed messages" 'mqtt' \
         'MQTT brokers' 'my.broker.mqtt:1883'

    ${_ASSERT_TRUE_} '"prozzie config -s mqtt must done with no failure"' $?

    while ! docker inspect --format='{{json .State.Health.Status}}' \
                    prozzie_kafka-connect_1| grep healthy >/dev/null; do :; done

    genericTestModule 14 mqtt 'name=mqtt' \
                              'mqtt.qos=1' \
                              'key.converter=org.apache.kafka.connect.storage.StringConverter' \
                              'value.converter=org.apache.kafka.connect.storage.StringConverter' \
                              'mqtt.server_uris=my.broker.mqtt:1883' \
                              'mqtt.topic=/my/mqtt/topic' \
                              'kafka.topic=mqtt' \
                              'tasks.max=1' \
                              'message_processor_class=com.evokly.kafka.connect.mqtt.sample.StringProcessor' \
                              'mqtt.client_id=my-id' \
                              'connector.class=com.evokly.kafka.connect.mqtt.MqttSourceConnector' \
                              'mqtt.clean_session=true' \
                              'mqtt.keep_alive_interval=60' \
                              'mqtt.connection_timeout=30'
}

#--------------------------------------------------------
# TEST SYSLOG MODULE
#--------------------------------------------------------

testSetupSyslogModuleVariables() {
    ${_ASSERT_TRUE_} '"prozzie config -s syslog must done with no failure"' \
        "'\"${PROZZIE_PREFIX}\"/bin/prozzie config -s syslog'"
}

testGetSyslogModuleVariables() {
    while ! docker inspect --format='{{json .State.Health.Status}}' prozzie_kafka-connect_1| grep healthy >/dev/null; do :; done

    genericTestModule 11 syslog 'name=syslog' \
                                'key.converter=org.apache.kafka.connect.json.JsonConverter' \
                                'value.converter=org.apache.kafka.connect.json.JsonConverter' \
                                'syslog.structured.data=true' \
                                'kafka.topic=syslog' \
                                'tasks.max=1' \
                                'syslog.port=1514' \
                                'syslog.host=0.0.0.0' \
                                'key.converter.schemas.enable=false' \
                                'connector.class=com.github.jcustenborder.kafka.connect.syslog.UDPSyslogSourceConnector' \
                                'value.converter.schemas.enable=false'
}

#--------------------------------------------------------
# TEST RESILIENCE
#--------------------------------------------------------

testDescribeWrongModule() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config --describe wrongModule; then
        ${_FAIL_} '"prozzie config --describe wrongModule must show error"'
    fi
}

testDescribeMustShowHelpIfModuleIsNotPresent() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config --describe; then
        ${_FAIL_} '"prozzie config --describe must show help with failure"'
    fi
}

testDescribeMustShowAnErrorIfModuleDoesNotExist() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config --describe wrongModule; then
        ${_FAIL_} '"prozzie config --describe wrongModule must show error"'
    fi
}

testSetupMustShowHelpIfModuleIsNotPresent() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config --setup; then
        ${_FAIL_} '"prozzie config --setup must show help with failure"'
    fi
}

testConfigMustShowErrorIfModuleIsNotExist() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config wrongModule; then
        ${_FAIL_} '"prozzie config wrongModule must show error"'
    fi
}

testConfigMustShowHelpIfTryToSetMqttAndSyslogModules() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config mqtt kafka.topic myTopic; then
        ${_FAIL_} '"prozzie config mqtt kafka.topic myTopic must show help"'
    fi
    if "${PROZZIE_PREFIX}"/bin/prozzie config syslog kafka.topic myTopic; then
        ${_FAIL_} '"prozzie config syslog kafka.topic myTopic must show help"'
    fi
}

testSetupCancellation() {
    declare md5sum_file temp_file=$(mktemp)
    exec {md5sum_file}>"${temp_file}"
    rm "${temp_file}"


    genericSetupQuestionAnswer base \
        'Data HTTPS endpoint URL (use http://.. for plain HTTP)' \
            'blah.blah.blah' \
        'Interface IP address' 'blah.blah.blah.blah' \
        'Client API key' 'blahblahblah'

    md5sum "${PROZZIE_PREFIX}"/etc/prozzie/.env > "/dev/fd/${md5sum_file}"

    genericSetupQuestionAnswer base \
        'Data HTTPS endpoint URL (use http://.. for plain HTTP)' \
            'https://my.test.endpoint' \
        'Interface IP address' "${INTERFACE_IP}" \
        'Client API key' '\x03'

    ${_ASSERT_TRUE_} "\".ENV file mustn\'t be modified\"" \
                                            "'md5sum -c \"/dev/fd/${md5sum_file}\"'"

    genericSetupQuestionAnswer base \
        'Data HTTPS endpoint URL (use http://.. for plain HTTP)' \
            'https://my.test.endpoint' \
        'Interface IP address' "${INTERFACE_IP}" \
        'Client API key' 'mySuperApiKey'

    if md5sum -c "/dev/fd/${md5sum_file}"; then
        ${_FAIL_} "\".ENV file must be modified\""
    fi
}

#--------------------------------------------------------
# TEST WIZARD
#--------------------------------------------------------

testWizard() {
    genericSpawnQuestionAnswer "${PROZZIE_PREFIX}/bin/prozzie config -w" \
         'Do you want to configure modules? (Enter for quit)' '{f2k} {}' \
         'JSON object of NF probes (It'\''s recommend to use env var)' '\{\}' \
         'Topic to produce netflow traffic?' 'wizardFlow'

    genericTestModule 2 f2k 'NETFLOW_KAFKA_TOPIC=wizardFlow' \
                            'NETFLOW_PROBES={}'
}

#--------------------------------------------------------
# TEST ENABLE AND DISABLE MODULES
#--------------------------------------------------------

testEnableModule() {
    "${PROZZIE_PREFIX}/bin/prozzie" config --enable f2k monitor

    if [[ ! -L "${PROZZIE_PREFIX}/etc/prozzie/compose/f2k.yaml" ]];then
        ${_FAIL_} '"prozzie config --enable must link f2k compose file"'
    fi

    if [[ ! -L "${PROZZIE_PREFIX}/etc/prozzie/compose/monitor.yaml" ]];then
        ${_FAIL_} '"prozzie config --enable must link monitor compose file"'
    fi
}

testDisableModule() {
    "${PROZZIE_PREFIX}/bin/prozzie" config --disable f2k

    if [[ -L "${PROZZIE_PREFIX}/etc/prozzie/compose/f2k.yaml" ]];then
        ${_FAIL_} '"prozzie config --disable must to unlink f2k compose file"'
    fi
}

. test_run.sh
