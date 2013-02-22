#!/bin/sh

set -e
# We will configure named and dhclient using the given domain name and the
# given IP address, so verify that they are provided and that the IP address
# can be pinged.
if test x = x$domain || test x = x$ip_addr
then
  echo "Usage: domain=<domain> ip_addr=<ip-address> $0"
  echo "Example: domain=example.com ip_addr=10.4.59.42 $0"
  exit 1
fi

if ! ping -c 1 $ip_addr >/dev/null 2>&1
then
  echo "Could not ping given IP address: $ip_addr"
  exit 2
fi

# Print a user-friendly message.
cat <<EOF
Using domain '${domain}' and IP address '${ip_addr}'.

This script configures DNS on your broker host using the domain name and IP
address you provided.  In particular, it performs the following steps:

* Install BIND and associated utilities.

* Generate a DNSSEC key and an RDNC key.

* Set appropriate ownership, permissions, SELinux contexts, and firewall rules
  to enable BIND to run and to allow remote hosts to connect.

* Configure an initial BIND database and add the broker host to this database.

* Configure BIND (named) with these keys and some forwarders, set it to start
  on reboots, and start it up now..

* Configure this host to use its local BIND server.

* Configure this host's DHCP server to preserve the previous configuration
  step.

EOF

echo; echo 'Installing the BIND packages...'; echo
yum install bind bind-utils -y

# We will configure named to use the keyfile at the following location, which
# is based on the domain name.
keyfile=/var/named/${domain}.key

# The DNSSEC key will be located in /var/named, so change to that directory
# now.
cd /var/named

echo; echo 'Generating DNSSEC key...'; echo
rm -f K${domain}*
dnssec-keygen -a HMAC-MD5 -b 512 -n USER -r /dev/urandom ${domain}
KEY="$(grep Key: K${domain}*.private | cut -d ' ' -f 2)"

# The following commands need not be performed in /var/named.
cd -

echo; echo 'Generating RNDC key...'; echo
rndc-confgen -a -r /dev/urandom  

# Ensure that the RNDC key and BIND configuration files have proper ownership,
# UNIX permissions, and SELinux contexts.
echo; echo 'Setting ownership, permissions, and SELinux contexts...'; echo
restorecon -v /etc/rndc.* /etc/named.*
chown -v root:named /etc/rndc.key
chmod -v 640 /etc/rndc.key 

# 8.8.8.8 and 8.8.4.4 are DNS servers provided by Google for general public
# use.
echo; echo 'Configuring forwarders...'; echo
echo "forwarders { 8.8.8.8; 8.8.4.4; } ;" > /var/named/forwarders.conf

# Ensure that forwarders has proper UNIX permissions and SELinux contexts.
echo; echo 'Setting permissions and SELinux contexts...'; echo
restorecon -v /var/named/forwarders.conf
chmod -v 755 /var/named/forwarders.conf

# Create a directory for BIND to store its database, after deleting any
# existing directory that may exist.
echo; echo 'Creating initial BIND database...'; echo
rm -rvf /var/named/dynamic
mkdir -vp /var/named/dynamic

# Create an initial BIND database.
cat <<EOF > /var/named/dynamic/${domain}.db
\$ORIGIN .
\$TTL 1 ; 1 seconds (for testing only)
${domain}       IN SOA  ns1.${domain}. hostmaster.${domain}. (
            2011112904 ; serial
            60         ; refresh (1 minute)
            15         ; retry (15 seconds)
            1800       ; expire (30 minutes)
            10         ; minimum (10 seconds)
            )
        NS  ns1.${domain}.
        MX  10 mail.${domain}.
\$ORIGIN ${domain}.
ns1         A   ${ip_addr}
EOF

# Configure BIND to use the DNSSEC key we generated above.
echo; echo 'Configuring BIND...'; echo
cat <<EOF > /var/named/${domain}.key  
key ${domain} {  
  algorithm HMAC-MD5;  
  secret "${KEY}";  
};
EOF

# Ensure that the BIND data files have proper UNIX permissions and SELinux
# contexts.
chown -Rv named:named /var/named
restorecon -rv /var/named

# Create the main configuration file for BIND.
cat <<EOF > /etc/named.conf
// named.conf

options {
    listen-on port 53 { any; };
    directory   "/var/named";
    dump-file   "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query     { any; };
    recursion yes;

    /* Path to ISC DLV key. */
    bindkeys-file "/etc/named.iscdlv.key";

    // Set forwarding to the next nearest server (from DHCP response.
    forward only;
        include "forwarders.conf";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

// Use the default rndc key.
include "/etc/rndc.key";

controls {
    inet 127.0.0.1 port 953
    allow { 127.0.0.1; } keys { "rndc-key"; };
};

include "/etc/named.rfc1912.zones";

// Use the DNSSEC key we generated.
include "${domain}.key";

zone "${domain}" IN {
    type master;
    file "dynamic/${domain}.db";
    allow-update { key ${domain} ; } ;
};
EOF

# Ensure that this file has correct ownership and SELinux context.
echo; echo 'Setting permissions and SELinux contexts...'; echo
chown -v root:named /etc/named.conf
restorecon /etc/named.conf

# Configure the host to use the local BIND server, which we have just
# configured, as its primary nameserver.
echo; echo 'Configuring resolv.conf...'; echo
mv -f /etc/resolv.conf /etc/resolv.conf.orig
echo 'nameserver 127.0.0.1' > /etc/resolv.conf

# Ensure that remote hosts (e.g., the node host) can connect to the BIND server
# running on this host.
echo; echo 'Configuring firewall...'; echo
lokkit --service=dns

# Ensure that the BIND server starts when this host is rebooted.
echo; echo 'Configuring named to start on boot...'; echo
chkconfig named on  

# Start the BIND server now.
echo; echo 'Starting named...'; echo
service named start

# Add a DNS entry for broker.${domain}.com pointing to this host.
echo; echo 'Adding the broker host to BIND database...'; echo
nsupdate -k ${keyfile} <<EOF
server 127.0.0.1
update delete broker.${domain} A
update add broker.${domain} 180 A ${ip_addr}
send
EOF

# Configure the DHCP client to preserve thechanges to resolv.conf and set the
# correct hostname.
echo; echo 'Configuring the DHCP client...'; echo
cat <<EOF > /etc/dhcp/dhclient-eth0.conf
prepend domain-name-servers ${ip_addr};
supersede host-name "broker";  
supersede domain-name "${domain}";
EOF

echo; echo 'Configuring the hostname...'; echo
sed -i -e "s/HOSTNAME=.*/HOSTNAME=broker.${domain}/" /etc/sysconfig/network
hostname "broker.${domain}"

echo; echo 'Script execution is complete.'
