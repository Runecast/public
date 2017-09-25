Setting up log forwarding from Splunk to Runecast Analyzer
==================================================

In case you already use Splunk to analyze logs of your vSphere infrastructure, but want also to have Runecast's Log->KB correlation, you don't need to setup Runecast Analyzer as an additional syslog server for your ESXi hosts. You can configure Splunk to forward the vSphere infrastructure logs to Runecast Analyzer for KB correlation. 


----------
**Splunk configurations:**
The following link can be used as reference for setting up syslog forwarding: http://docs.splunk.com/Documentation/SplunkCloud/6.6.1/Forwarding/Forwarddatatothird-partysystemsd#Syslog_data

Based on the instructions from Splunk, the example below will forward syslog messages from hosts with hostname starting with 10.1.141.10*. To achieve that 3 configuration files needs to be set up:

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

The files are also part of this repo. In order the changes to take effect the Splunk service needs to be restarted. 


----------

**Runecast Analyzer configurations:**
In order Runecast to be able to parse correctly the forwarded logs, additional filter needs to be set. For convenience, script for adding the filter is available on our public github repository. Below is how it can be downloaded and executed from Runecast Analyzer:

1. Log in to Runecast Analyzer via console (default credentials: rcadmin / admin)
2. Download the file with - wget https://raw.githubusercontent.com/Runecast/rcpub/master/addFilter.sh (it will download at the current location)
3. Mark as executable - chmod +x addFilter.sh
4. Execute the script as root (default password: admin) - sudo ./addFilter.sh. The script will add the custom filter and restart logstash service.

After that the Splunk logs should be visible from Runecast Analyzer GUI.

Thanks!
