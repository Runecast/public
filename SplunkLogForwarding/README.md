1. Splunk - as this tools has many capabilities and different approaches on setting up, I can cover the basic example of setting the forwarding. The example below will forward syslog messages from hosts with hostname starting with 10.1.141.10*. To achieve that 3 configuration files needs to be set up:

props.conf
--------------------
[host::10.1.141.10*]
TRANSFORMS-10.1.141.10 = to_rc_syslog

transforms.conf
------------------------
[to_rc_syslog]
REGEX = .
DEST_KEY = _SYSLOG_ROUTING
FORMAT = rc_syslog_group

outputs.conf
-----------------------
[syslog:rc_syslog_group]
server = 10.1.3.200:514
type = udp

The files are also attached in the email. In order the changes to take effect the Splunk service needs to be restarted. The following link can be used as reference for setting up syslog forwarding: http://docs.splunk.com/Documentation/SplunkCloud/6.6.1/Forwarding/Forwarddatatothird-partysystemsd#Syslog_data

2. Runecast Analyzer - in order Runecast to be able to parse correctly the forwarded logs, additional filter needs to be set. For convenience, script for adding the filter is available on our public github repository. Below is how it can be downloaded and executed from Runecast Analyzer:
2.1 Log in to Runecast Analyzer via console (default credentials: rcadmin / admin)
2.2 Download the file with - wget https://raw.githubusercontent.com/Runecast/rcpub/master/addFilter.sh (it will download at the current location)
2.3 Mark as executable - chmod +x addFilter.sh
2.4 Execute the script as root (default password: admin) - sudo ./addFilter.sh. The script will add the custom filter and restart logstash service.

After that the logs should be visible from Runecast Analyzer.

Thanks!
