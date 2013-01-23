#**Appendix A - Troubleshooting**

##**Diagnostics script**

Installing and configuring an OpenShift Enterprise PaaS can often fail due to simple mistakes in configuration files.  Fortunately,  the team provides an unsupported troubleshooting script that can diagnose most problems with an installation.  This script is located on the lab support website and is called *oo-diagnostics*.  For this lab, running the version provided on the support website should suit your needs but when helping customers out, I suggest you pull the script from the official github repository to ensure that you have most updated version.  The github script can is located at:

	https://raw.github.com/openshift/origin-server/master/util/oo-diagnostics
	
This script can be run on any OpenShift Enterprise broker or node host.  Once you have the script downloaded, change the permission to enable execution of the script:

	# chmod +x oo-diagnostics
	
To run the command and check for errors, issue the following command:

	# ./oo-diagnostics -v
	
**Note:** Sometimes the script will fail at the first error and not continue processing.  In order to run a full check on your node, add the *--abortok* switch
	
	# ./oo-diagnostics -v --abortok
	
Under the covers, this script performs a lot of checks on your host as well as executing the existing *oo-accept-broker* and *oo-accept-node* commands on the respective host.

##**Recovering failed nodes**

A node host that fails catastrophically can be recovered if the gear directory /var/lib/openshift has been stored in a fault-tolerant way and can be recovered. In practice this scenario occurs rarely, especially when node hosts are virtual machines in a fault tolerant infrastructure rather than physical machines. 

**Note: Do not start the MCollective service until you have completed the following steps.**

Install a node host with the same hostname and IP address as the one that failed. The hostname DNS A record can be adjusted if the IP address must be different, but note that the application CNAME and database records all point to the hostname, and cannot be easily changed.

Duplicate the old node host's configuration on the new node host, ensuring in particular that the gear profile is the same. 

Mount */var/lib/openshift* from the original, failed node host. SELinux contexts must have been stored on the */var/lib/openshift* volume and should be maintained. 

Recreate /etc/passwd entries for all the gears using the following steps:

* Get the list of UUIDs from the directories in /var/lib/openshift.
* Get the Unix UID and GID values from the group value of /var/lib/openshift/UUID.
* Create the corresponding entries in /etc/passwd, using another node's /etc/passwd file for reference. 

Reboot the new node host to activate all changes, start the gears, and allow MCollective and other services to run. 

##**Removing applications from a node**

While trying to add a node to a district, a common error is that the node already has user applications on it.  In order to be able to add this node to a district, you will either need to move these applications to another node or delete the applications.  In this training class, it is suggested that you simply delete the application as we are working in a single node host configuration.  In order to remove a users application, issue the following commands:

	# oo-admin-ctl-app -l username -a appname -c stop
	# oo-admin-ctl-app -l username -a appname -c destroy
	
The above commands will stop the users application and them remove the application from the node.  If you want to preserve the application data, you should backup the application first using the snapshot tool that is part of the RHC command line tools.

<!--BREAK-->

#**Appendix B - RHC command line reference**

<!--BREAK-->



