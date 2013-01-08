Title:  OpenShift Enterprise Training - Lab Manual
Author: Grant Shipley  
Date:   Jan, 2013
* Email: gshipley@redhat.com[]() 

#**OpenShift Enterprise Administration Training - Lab Manual**




Author: Grant Shipley

Revision: 1.0

<!--BREAK-->

#**1.0 An overview of OpenShift Enterprise**
##**1.1 Assumptions**
This lab manual assumes that you are attending an instrcutor led training class and that you will be using this lab manual in conjuction with the lecture.  

I also assume that you have been granted access to two Red Hat Enteprise Linux servers with which to perform the exercises in this lab manual.  If you do not have access to your servers, please notify the instructor.

A working knowledge of SSH, git, yum, and familarity with a linux based text editor.  If you do not have an understanding of any of these technologies, please let the instructor know.

##**1.2 What you can expect to learn from this training class**

At the conclusion of this training class, you should have a solid understanding of how to install and configure OpenShift Enterprise.  You should also feel comfortable in the usage of create and deploying application using the OpenShift Enterprise web console, command line tools, and JBoss Developer Studio.

##**1.3 An overview of OpenShift Enterprise PaaS**

Platform as a service is changing the way developers approach developing software. Developers typically use a local sandbox with their preferred application server and only deploy locally on that instance. Developers typically start JBoss locally using the startup.sh command and drop their .war or .ear file in the deployment directory and they are done.  Developers have a hard time understanding why deploying to the production infrastructure is such a time consuming process.

System Adminstrators understand the complexity of not only deploying the code, but procuring, provisioning and maintaining a production level system. They need to stay up to date on the latest security patches and errata, ensure the firewall is properly configured, maintain a consistent and reliable backup and restore plan, monitor the application and servers for cpu load, disk io, http requests, etc.

OpenShift Enterprise provides developers and IT organizations an auto-scaling cloud application platform for quickly deploying new applications on secure and scalable resources with minimal configuration and management headaches. This means increased developer productivity and a faster pace in which IT can support innovation.

This manual will walk you through the process of installing and configuring an OpenShift Enterprise environment as part of this two day training class that you are attending.

##**1.4 An overview of IaaS**

The great thing about OpenShift Enterprise is that we are infrastructure agnostic. You can run OpenShift on bare metal, virtualized, or on public/private cloud instances. The only thing that is required is Red Hat Enterprise Linux as the underlying operating system. We require this in order to take advantage of SELinux and other enterprise features so that you can ensure your installation is rock solid and secure.

What does this mean? This means that in order to take advantage of OpenShift Enterprise, you can use any existing resources that you have in your hardware pool today. It doesn’t matter if your infrastructure is based on EC2, VMWare, RHEV, Rackspace, OpenStack, CloudStack, or even bare metal as we run on top of any Red Hat Enterprise Linux operating system.

For this training class will be using OpenStack as our infrastructure as a service layer.

##**1.5 Using the kickstart script**

In this training class, we are going to go into the details of installing and configuring all of the components required for OpenShift Enterprise.  We will be installing and configuring bind, MongoDB, DHCP, ActiveMQ, MCollective, and other vital pieces to OpenShift.  Doing this manually will give you a better understanding of how all of the components of OpenShift Enterprise work together to create a complete solution.

That being said, once you have a solid understanding of all of the moving pieces, you will probably want to take advantage of our kickstart script that performs all the functions in the administration portion of this training on your behalf.  This script will be allow you create complete OpenShift Enterprise environments in a matter of minues.

The kickstart script is located at:
https://mirror.openshift.com/pub/enterprise-server/scripts/1.0/

When using the kickstart script, be sure to edit the script to use the correct Red Hat subscriptions.  Take a look at the script header for full instructions.

##**1.6 Electronic version of this document**

This lab manual contains many configuration items that will need to be performed on your broker and node hosts.  Manually typing in all of these values would be a tedious and error prone effort.  To alleviate the risk of errors, and to let you concentrate on learning the material instead of typing tedious configuration items, an electronic version of the document is available at the following URL:

	http://training.onopenshift.com
	

<!--BREAK-->

#**Lab 1: Register and update your Operating system (Estimated time: xx minutes)**

**Server Used:**

Broker host

**Tools used**

* SSH
* subscription-manager
* ntpdate
* yum


##**Register system and apply subscription**

In order to be able to update to newer packages, and to download the OpenShift Enterprise software, your system will need to be registered with Red Hat to allow your system access to appropriate software channels.  You will need the following subscription at a minimum for this class.

*Red Hat Enterprise Linux Employee Subscription
*OpenShift Enterprise Employee Subscription

The machines provided to you in this lab have already been registered with the production Red Hat Network.  However, they have not been enabled for the above subscriptions.  List all of the available subscriptions for the account that has been registered for you:

	# subscription-manager list —available	
	
From the list provided, subscribe to Red Hat Enterprise Linux.

	# subscription-manager subscribe —pool [POOL IID from previous command]
	
Once you have subscribed to Red Hat Enterprise Linux, the next step is subscribe to the OpenShift Enterprise Employee subscrption.  Complete that step and then verify that you are subscribed to both RHEL and OpenShift Enterprise.

	# subscription-manager list —consumed
	
Also, take note of the yum repositories that you are now able to install packages from.

	# yum repolist
	
##**Update operating system to latest packages**

We need to update the operating system to have all of the latest packages that may be in the yum repository for RHEL Server. This is important to ensure that you have a recent update to the SELinux packages that OpenShift Enterprise relies on. In order to update your system, issue the following command:

	# yum update
	
Depeding on the network connectivity at this location, this update may take several minutes.  

##**Configuration of clock to avoid clock skew**

OpenShift Enterprise requires NTP to synchronize the system and hardware clocks. This synchronization is necessary for communication between the broker and node hosts; if the clocks are too far out of synchronization, MCollective will drop messages.  Every MCollective request (discussed in a later lab) includes a time stamp, provided by the sending host's clock. If a sender's clock is substantially behind a recipient's clock, the recipient drops the message.  This is often referred to as clock skew as is a common problem that users encounter when they fail to sync all of the system clocks.

	# ntpdate clock.redhat.com
	
**Lab 1 Complete!**

<!--BREAK-->

#**Lab 2: Installation and configuration of DNS (Estimated time: xx minutes)**

**Server Used:**

Broker host

**Tools used**

* SSH
* bind
* text editor (vi, emacs, nano, etc)
* environment variables
* SELinux
* Commands: cat, echo, chown, dnssec-keygen, rnds-confgen, restorecon, chmod, lokkit, chkconfig, service, nsupdate, ping, dig

##**Install DNS Server**

In order for OpenShift Enterprise to work correctly, you will need configure bind so that you have a DNS server setup.  At a typical customer site, they will have an existing DNS infrastructure in place.  However, for the purpose of this training class, we need to install and configure our own server so that name resolution works properly.  Primarily, we will be using name resolution for communication between our broker and node servers as well as dynamically updating our dns server to resolve gear application names when we start creating application gears.

This lab starts off by requiring the installation of both *bind* and *bind-utils* packages.

	# yum install bind bind-utils
	
##**Create environment variables and DNSSEC key file**

The official OpenShift documentation suggests that you set an environment variable for the domain name that you will be using which allow faster configuration of bind. Let’s follow the suggested route for this training class by issuing the following command:

	# domain=example.com
	
DNSSEC, which stands for DNS Security Extensions, is a method by which DNS servers can verify that DNS data is coming from the correct place.  You create a private/public key pair to determine to authenticaticty of the source domain name.  In order to implement DNSSEC on our OpenShift Enterprise broker node, we need to create a key file.

	# keyfile=/var/named/${domain}.key
	
Create a DNSSEC key pair and store the key in a variable named key by using the following commands:

	# cd /var/named
	# dnssec-keygen -a HMAC-MD5 -b 512 -n USER -r /dev/urandom ${domain}
	# KEY="$(grep Key: K${domain}*.private | cut -d ' ' -f 2)"
	# cd -
	# rndc-confgen -a -r /dev/urandom

Verify that the key was created properly by viewing the contents of the key variable:

	# echo $KEY
	
Configure the ownership, permissions, and SELinux context for the key we created.

	# restorecon -v /etc/rndc.* /etc/named.*
	# chown -v root:named /etc/rndc.key
	# chmod -v 640 /etc/rndc.key

##**Create fowards.conf configuration file for host name resolution**

The DNS forwarding facility of BIND can be used to create a large site-wide cache on a few servers, reducing traffic over links to external nameservers. It can also be used to allow queries by servers that do not have direct access to the Internet, but wish to look up exterior names anyway. Forwarding occurs only on those queries for which the server is not authoritative and does not have the answer in its cache.

Create a forwards.conf file with the following commands:

	# echo "forwarders { 8.8.8.8; 8.8.4.4; } ;" >> /var/named/forwarders.conf
	# restorecon -v /var/named/forwarders.conf
	# chmod -v 755 /var/named/forwarders.conf
	
##**Configure subdomain resolution and create database**

To ensure that we are starting with a clean */var/named/dynamic* directory, lets remove this directory if it exists.

	# rm -rvf /var/named/dynamic
	# mkdir -vp /var/named/dynamic
	
Issue the following command to create ${domain}.db file. Before running this command, verify that you the domain variable you set earlier in this lab is available to your current session.

	cat <<EOF > /var/named/dynamic/${domain}.db
	\$ORIGIN .
	\$TTL 1	; 1 seconds (for testing only)
	${domain}		IN SOA	ns1.${domain}. hostmaster.${domain}. (
				2011112904 ; serial
				60         ; refresh (1 minute)
				15         ; retry (15 seconds)
				1800       ; expire (30 minutes)
				10         ; minimum (10 seconds)
				)
			NS	ns1.${domain}.
			MX	10 mail.${domain}.
	\$ORIGIN ${domain}.
	ns1			A	127.0.0.1
	EOF
	
Once you have entered the above echo command, cat the contents of the file to ensure that the command was successful.

	# cat /var/named/dynamic/${domain}.db
	
You should see the following output:

	$ORIGIN .
	$TTL 1  ; 1 second
	example.com             IN SOA  ns1.example.com. hostmaster.example.com. (
	                                2011112916 ; serial
	                                60         ; refresh (1 minute)
	                                15         ; retry (15 seconds)
	                                1800       ; expire (30 minutes)
	                                10         ; minimum (10 seconds)
	                                )
	                        NS      ns1.example.com.
	                        MX      10 mail.example.com.
	$ORIGIN example.com.
	ns1                     A       127.0.0.1
	
Now we need to install the DNSSEC key for our domain:
	
	cat <<EOF > /var/named/${domain}.key
	key ${domain} {
	  algorithm HMAC-MD5;
	  secret "${KEY}";
	};
	EOF
	
Set the correct permissions and context:

	# chown -Rv named:named /var/named
	# restorecon -rv /var/named

##**Create our named configuration file**

We also need to create our named.conf file,   Before running this command, verify that you the domain variable you set earlier in this lab is available to your current session.

	cat <<EOF > /etc/named.conf
	// named.conf
	//
	// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
	// server as a caching only nameserver (as a localhost DNS resolver only).
	//
	// See /usr/share/doc/bind*/sample/ for example named configuration files.
	//
	
	options {
		listen-on port 53 { any; };
		directory 	"/var/named";
		dump-file 	"/var/named/data/cache_dump.db";
	        statistics-file "/var/named/data/named_stats.txt";
	        memstatistics-file "/var/named/data/named_mem_stats.txt";
		allow-query     { any; };
		recursion yes;
	
		/* Path to ISC DLV key */
		bindkeys-file "/etc/named.iscdlv.key";
	
		// set forwarding to the next nearest server (from DHCP response
		forward only;
	        include "forwarders.conf";
	};
	
	logging {
	        channel default_debug {
	                file "data/named.run";
	                severity dynamic;
	        };
	};
	
	// use the default rndc key
	include "/etc/rndc.key";
	
	controls {
		inet 127.0.0.1 port 953
		allow { 127.0.0.1; } keys { "rndc-key"; };
	};
	
	include "/etc/named.rfc1912.zones";
	
	include "${domain}.key";
	
	zone "${domain}" IN {
		type master;
		file "dynamic/${domain}.db";
		allow-update { key ${domain} ; } ;
	};
	EOF
	
And finally, set the permissions for the new configuration file that we just created.

	# chown -v root:named /etc/named.conf
	# restorecon /etc/named.conf

##**Configure host name resolution to use new bind server**

We need to update our resolve.conf file to use our local *named* service that we just installed and configured.  Open up your */etc/resolv.conf* file and add the following entry:

	nameserver 127.0.0.1
	
We also need to make sure that *named* starts on boot and the firewall is configured to pass through dns traffic.

	# lokkit --service=dns
	# chkconfig named on
	
##**Start *named* service**

We are finally ready to start up our new dns server and add some updates.

	# service named start
	
You should see a confirmation message that the service was started correctly.  If you do not see an OK message, I would suggest running through the above steps again and ensure that the output of each command matches the contents of this exercise.  If you are still having trouble after trying the steps again, ask the instructor for help.

##**Add entries using nsupdate**

Now that our bind server is configured and started, we need to add our broker node to our DNS entries.  To accomplish this task, we will use the nsupdate command, which opens an interactive shell where we can perform commands.

	# nsupdate -k ${keyfile}
	> server 127.0.0.1
	> update delete broker.example.com A
	> update add broker.example.com 180 A ${your system ip address}
	> send
	
Press control-D to exit from the interactive session.

In order to verify that you have successfully added broker.example.com to your dns server, you can perform

	# ping broker.example.com
	
and it should resolve to the local machine that you are working on.  You can also perform a dig request using the following command:

	# dig @127.0.0.1 broker.example.com
	
**Lab 2 Complete!**

<!--BREAK-->

#**Lab 3: Configure dhclient-eth0.conf and setting the hostname (Estimated time: xx minutes)**

**Server Used:**

Broker host

**Tools used**

* text editor
* Commands: hostname

##**Create dhclient-eth0.conf**

In order to configure your broker host to use a DNS server that we installed in a previous lab, you will need to edit the */etc/dhcp/dhclient-{$network device}.conf file*.  Without this step, the DNS server information in resolve.conf would default back the server returned from your DHCP server on the next boot of the server.  For example, if you are using eth0 as your default ethernet device, you would need to edit the following file:

	/etc/dhcp/dhclient-eth0.conf
	
If you are unsure of which network device that your system is using, you can issue the *ifconfig* command to list all available network devices for your machine.  Note, the *lo* device is the loopback device and is not the one you are looking for.

Once you have the correct file opened, add the following information making sure to substitute the correct IP Address in place of 10.10.10.10

	prepend domain-name-servers 10.10.10.10;
	supersede host-name "broker";
	supersede domain-name "example.com";
	
##**Set the host name for your server**

You need to set the hostname of your broker node.  In order to accomplish this task, edit the */etc/sysconfig/network* file and locate the section labeled *HOSTNAME*.  The line that you want to replace should look like this:

	HOSTNAME=localhost.localdomain
	
We need to change this to reflect the new hostname that we are going to apply for this server.  For this lab, we will be using broker.example.com.  Change the */etc/sysconfig/network* file to reflect the following change:

	HOSTNAME=broker.example.com
	
Now that we have configured our hostname, we also need to set it for our current session but using the following command:

	# hostname broker.example.com


**Lab 3 Complete!**

<!--BREAK-->

#**Lab 4: Installation and Configuration of MongoDB (Estimated time: xx minutes)**

**Server Used:**

Broker host

**Tools used**

* text editor
* yum
* mongo
* chkconfig
* service


OpenShift Enterprise makes heavy use of MongoDB for storing internal information about users, gears, and other necessary items.  If you are not familiar with MongoDB, I suggest that you had over the offical MongoDB site (http://www.mongodb.org) to read up on this great NoSQL database.  For the puprose of this lab, you need to know that MongoDB is a document data storage system and uses javascript for the command syntax and stores all documents in a JSON format.

##**Install *mongod* server**

In order to use MongoDB, we will need to install the mongod server.  To accomplish this tasks on Red Hat Enterprise Linux with an OpenShift Enterprise subscription, simply issue the following command:

	# yum install mongodb-server

At the time of this writing, you should see the following package being installed:

| Package Name | Arch| Package Version|Repo|Size
| :----------------  | :--- |
| mongodb-server | x86_64  |  2.0.2-2.el6op |  rhel-server-ose-infra-6-rpms | 3.8 M |
| boost-program-options | x86_64  |  1.41.0-11.el6_1.2 |  rhel-6-server-rpms | 105 k |
| boost-thread  | x86_64  |  1.41.0-11.el6_1.2|  rhel-6-server-rpms | 105 k |
| libmongodb | x86_64  |  1.41.0-11.el6_1.2 |  rhel-6-server-rpms | 41 k |
| boost-program-options | x86_64  |  2.0.2-2.el6op | rhel-server-ose-infra-6-rpms | 531 k |
| mongodb | x86_64  |  2.0.2-2.el6op |  rhel-server-ose-infra-6-rpms | 21 M |
[Packages installed from mongodb-server][section-mmd-tables-table1] 

##**Configure *mongod* server**

 MongoDB uses a configuration file for its settings.  This file can be found at */etc/mongodb.conf*.  We need to make a few changes to this file to ensure that we handle authentication correctly and that we enable the ability to use small files.  Go ahead and edit the configuration file and ensure the two following conditions are set correctly:
 
 	auth=true
 	
 By default, this line is commented out so just remove the comment.  We also need to enable smallfiles, so add the following line.
 
 	smallfiles=true
 	
##**Confgure *mongod* to start on boot**

MongoDB is an essential part of the OpenShift Enterprise platform.  Because of this, we need to ensure that *mongod* is configured to start on system boot and we also need to ensure the database is started for our current use.  

	# chkconfig mongod on
	
By default, when you install *mongod* via the yum command, the service is not started.  You can verify this with the following:

	# service mongod status
	
This should return - *mongod is stopped*.  In order to start the service, simply issue

	# service mongod start
	
We need to verify that mongod was installed and configured correctly.  In order to do this, we are going to make use of the mongo shell client tool.  If you are more familair with mysql or postgres, this is similar to the mysql client where you are dropped into an interactive SQL shell.  Remember, MongoDB is a NoSQL database so the notion of entering SQL commands are non-existant.  In order to start the mongo shell, enter the following command:

	# mongo
	
You should see a confirmation message that you are using MongoDB shell version: 2.0.2 and that you are connecting to the test database.  To verify even further, let’s list all of the available databases that we currently have.

	> show dbs

You will then be presented with a list of valid databases that are currently available to the mongod service.

	admin   (empty)
	local   (empty)

**Lab 4 Complete!**

<!--BREAK-->

#**Lab 5: Installation and Configuration of ActiveMQ (Estimated time: xx minutes)**

**Server Used:**

Broker host

**Tools used**

* text editor
* yum
* wget
* lokkit
* chkconfig
* service

ActiveMQ is a fully open source messenger service that is available for use across many different programming languages and environments.  OpenShift Enterprise makes use of this technology to handle communications between the broker host and the node hosts in our deployment.  In order to make use of this messenging service, we need to install and configure ActiveMQ for use on our broker node.

##**Install ActiveMQ**

Installing ActiveMQ on Red Hat Enterprise Linux 6 is a fairly easy and straightforward process as the packages are included in the rpm repositories that are already configured on your broker node.  We want to install both the server and client packages by using the following command:

	# yum install activemq activemq-client
	
You will notice that is will also install any of the dependendicies required for the packages if you don’t already have them.  Notebally, java 1.6 and the libraries for use with the ruby programming language.

##**Configure ActiveMQ**

ActiveMQ uses an xml configuration file that is located at */etc/activemq/activemq.xml*.  Instead of creating a new configuration file from scratch, I suggest that you [download a sample configuration file] (https://mirror.openshift.com/pub/enterprise-server/scripts/1.0/activemq.xml) and make any necessary changes to the sample file.

	# cd /etc/activemq
	# mv activemq.xml activemq.orig
	# wget https://mirror.openshift.com/pub/enterprise-server/scripts/1.0/activemq.xml
	
The above command will backup the default configuration file that ships with ActiveMQ and replace it with one configured for use with OpenShift Enteprise.  Now that we have the configuration template, we need to make a few minor changes to the configuration.  

The first change we need to make is to replace the hostname provided (activemq.example.com) to the FQDN of your broker host. For example, the following line:

	<broker xmlns="http://activemq.apache.org/schema/core" brokerName="activemq.example.com" dataDirectory="${activemq.data}">
	
Should become:

	<broker xmlns="http://activemq.apache.org/schema/core" brokerName="broker.example.com" dataDirectory="${activemq.data}">
	

The second change is to provide your own credentials for authentication.  The authentication information is stored inside of the *<simpleAuthenticationPlugin>* block of code.  Make the changes that you desire to the following code block:

	<simpleAuthenticationPlugin>
       <users>
         <authenticationUser username="mcollective" password="marionette" groups="mcollective,everyone"/>
         <authenticationUser username="admin" password="secret" groups="mcollective,admin,everyone"/>
       </users>
     </simpleAuthenticationPlugin>
 
 ##**Modify firewall and configure ActiceMQ to start on boot**

We need to modify the firewall rules to allow MCollective to communicate on port 61613.  

	# lokkit --port=61613:tcp
	
Finally, we need to enable the ActiveMQ service to start on boot as well as start the service for the first time.

	# chkconfig activemq on
	# service activemq start
	
 ##**Verify ActiceMQ is working**

Now that ActiveMQ has been installed, configured, and started, let’s verify that the web console is working as expected.  ActiveMQ web console should be running and listening on port 8161.  In order to verify that everything worked correctly, load the following URL in a web browser:

	http://localhost:8161
	
**Note:** Given the current configuration, ActiveMQ is only available on the localhost.  If you want to be able to connect to it via http remotely, you will need to either enable a SSH port forwarding tunnel or you will need to add a rule to your firewall configuration:
	
	# lokkit --port=8161:tcp
	# ssh -f -N -L 8161:broker.example.com:8161 root@10.10.10.10


![title](file://localhost/Users/gshipley/Dropbox/Shifters/Blog%20Posts/Grant/Enterprise/images-post2/activemqconsole.png)

**Note:**  The above configuration required no authentication for accessing the activemq console.  For a production deployment, you would want to restrict access to localhost (127.0.0.1) and require authentication.  The authentication information is stored in the */etc/activemq/jetty.xml* configuration file as well as the */etc/activemq/jetty-realm.properties* file.

**Lab 5 Complete!**

<!--BREAK-->

#**Lab 6: Installation and Configuration of the MCollective client (Estimated time: xx minutes)**

**Server Used:**

Broker host

**Tools used**

* text editor
* yum

For communication between the broker host and the gear nodes, OpenShift Enterprise uses MCollective.  You may be wondering how MCollective is different from ActiveMQ, that we installed in a previous lab.  ActiveMQ is the messenger server that provides a queue of transport messages.  You can think of MCollective as the client that actually sends and receives those messages.  For example, if we want to create a new gear on an OpenShift Enterprise node, MCollective would receive the create gear message from ActiveMQ and perform the operation.

 ##**Installation of MCollective client**
 
 In order to use MCollective, we need to install and configure it.
	
	# yum install mcollective-client
	
 ##**Configuration of MCollective client**

Replace the contents of the */etc/mcollective/client.cfg* with the following information:

	topicprefix = /topic/
	main_collective = mcollective
	collectives = mcollective
	libdir = /usr/libexec/mcollective
	logfile = /var/log/mcollective-client.log
	loglevel = debug
	
	# Plugins
	securityprovider = psk
	plugin.psk = unset
	
	connector = stomp
	plugin.stomp.host = localhost
	plugin.stomp.port = 61613
	plugin.stomp.user = mcollective
	plugin.stomp.password = marionette
	
**Note:** Provide the correct information for your installation for the host, password, etc.


**Lab 6 Complete!**

<!--BREAK-->

#**Lab 7: Installation and Configuration of the Broker Application (Estimated time: xx minutes)**

**Server Used:**

Broker host

**Tools used**

* text editor
* yum
* sed
* chkconfig
* lokkit
* openssl
* ssh-keygen
* fixfiles
* restorecon
	
##**Install necessary packages for the broker application**
 
 In order for users to interact with the OpenShift Enteprise Platform, they will typically use client tools or the web console.  These tools communicate with the broker via a REST API that is also accessbile for writing third party applications and tools.  In order to use the broker application, we need to install several packages from the OpenShift Enterprise repository.

	# yum install openshift-origin-broker openshift-origin-broker-util rubygem-openshift-origin-auth-remote-user rubygem-openshift-origin-msg-broker-mcollective rubygem-openshift-origin-dns-bind
	
**Note:** Depending on your connection and speed of your broker server, this installation make take several minutes.

##**Modify the Broker Proxy Server Name**

The default value of the ServerName property is localhost, and you need to change this to accurately reflect your broker's host name. Run the following command to update your broker's host name using sed: 

	# sed -i -e "s/ServerName .*$/ServerName `hostname`/" /etc/httpd/conf.d/000000_openshift_origin_broker_proxy.conf
	
**Note:** You can also manually update the */etc/httpd/conf.d/000000_openshift_origin_broker_proxy.conf* and modify the ServerName attribute to reflect the corrent hostname.
  
##**Configure start on boot and firewall for services**

The broker application requires a number of services to be running in order to function properly.  Instead of having to start these services each time the server boots, we can add them to startup at boot time.

	# chkconfig httpd on
	# chkconfig network on
	# chkconfig ntpd on
	# chkconfig sshd on
	
We also need to modify the firewall rules to ensure that the traffic for these services are accepted:

	# lokkit --service=ssh
	# lokkit --service=https
	# lokkit --service=http
	
##**Generate Access Keys**

We now need to generate access keys that will allow some of the services, Jenkins for example, to communicate to the broker. 
	
	# openssl genrsa -out /etc/openshift/server_priv.pem 2048
	# openssl rsa -in /etc/openshift/server_priv.pem -pubout > /etc/openshift/server_pub.pem
	
We also need to generate a ssh key pair that will allow communication between the broker host and any nodes that you have configured.  Remember, the broker host is the dirctor of communications and the node hosts actually contain all of the application gears that your users create.  In order to generate this SSH keypair, perform the following commands:

	# ssh-keygen -t rsa -b 2048 -f ~/.ssh/rsync_id_rsa
	# cp ~/.ssh/rsync_id_rsa* /etc/openshift/
	
In a later lab that covers configuration of the node hosts, we will copy this newly created key to each node host.

##**Configure SELinux Variables and set proper contexts**

SELinux has several variablea that we want to ensure is set correctly.  These variables include the following:


| Variable Name | Description|
| :---------------  | :------------ |
| httpd_unified | Allow the broker to write files in the "http" file context | 
| httpd_can_network_connect | Allow the broker application to access the network | 
| httpd_can_network_relay  | Allow the SSL termination Apache instance to access the backend Broker application | 
| httpd_run_stickshift | Enable passenger-related permissions | 
| named_write_master_zones | Allow the broker application to configure DNS | 
| allow_ypbind | Allow the broker application to use ypbind to communicate directly with the name server | 
[SELinux Boolean Values][section-mmd-tables-table1] 

In order to set all of these variables correctly, enter the following:

	# setsebool -P httpd_unified=on httpd_can_network_connect=on httpd_can_network_relay=on httpd_run_stickshift=on named_write_master_zones=on allow_ypbind=on
	
We also need to set several files and directories with the proper SELinux contexts.  Issue the following commands:

	# fixfiles -R rubygem-passenger restore
	# fixfiles -R mod_passenger restore
	# restorecon -rv /var/run
	# restorecon -rv /usr/share/rubygems/gems/passenger-*


**Lab 7 Complete!**

<!--BREAK-->
<!--BREAK-->
<!--BREAK-->
#**Appendix A - Installation of Red Hat Enterprise Linux**

<!--BREAK-->

#**Appendix B - RHC command line reference**

<!--BREAK-->



