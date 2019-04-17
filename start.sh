#!/bin/bash

if [ $mode = "cci" ] ; then
  # set env vars to redsocks config
  sed -i -e "s/\${pep_addr}/${pep_addr}/g" /tmp/redsocks.conf
  
  # Cleanup iptables
  iptables-save | grep -v REDSOCKS | iptables-restore
  
  # First we added a new chain called 'REDSOCKS' to the 'nat' table.
  iptables -t nat -N REDSOCKS
  
  # Set proxy exceptions for docker0 bridge
  iptables -t nat -A REDSOCKS -d ${pep_addr}/32 -j RETURN
  
  iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
  
  iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
  
  iptables -t nat -A REDSOCKS -d 100.64.0.0/10 -j RETURN
  
  iptables -t nat -A REDSOCKS	-d 127.0.0.0/8 -j RETURN
  
  iptables -t nat -A REDSOCKS	-d 169.254.0.0/16 -j RETURN
  
  iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
  
  iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
  
  iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
  
  iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
  
  # Allow ssh to the instance if neccessary
  iptables -t nat -A REDSOCKS -p tcp -m tcp --dport 22 -j ACCEPT
  
  # We then told iptables to redirect all the other connections to the http-relay redsocks port and all other connections to the http-connect redsocks port.
  iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345
  
  # Finally we tell iptables to use the ‘REDSOCKS’ chain for all docker traffic
  iptables -t nat -A PREROUTING -p tcp -j REDSOCKS
  iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
  
  # Starting redsocks
  echo "Starting redsocks..."
  /usr/bin/redsocks -c /tmp/redsocks.conf &
else
  echo $mode
fi

