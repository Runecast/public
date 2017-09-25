#!/bin/bash
echo "Adding custom filter"
sed -i '17s/$/,\r\n"message", "%{IPV4:host} %{TIMESTAMP_ISO8601:@timestamp} %{SYSLOGHOST:hostname} %{SYSLOGPROG}: %{GREEDYDATA:message-syslog}"/' /etc/logstash/conf.d/RClogDefs.conf
echo "Restarting logstash service"
service logstash restart
