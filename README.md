# check_network

## Description :
This bash script will allow to check the protocol/port and network flow on a ascii map.

## Prerequisites :
create an linux user called ssh_user on current server and remote server
install a SSH key to authenticate as ssh_user, to be able to connect like :
````
sudo -u ssh_user ssh ssh_user@remote_server 
````
install network tools on current server and remote server :
````
nc, tcpdump, netstat
````

## How to use the ncheck.sh script : 
````bash
 ./ncheck.sh  -H "10.25.15.133" -D "10.25.12.240" -P "TCP" -p "1234"
````
example of result : 
![image](https://github.com/alexvea/check_network/assets/35368807/fc267b12-e15f-48b2-abea-74e6f4fd6c85)




## Help :
````
The script will help to check port/network flow and UDP/TCP/ICMP protocol.
Syntax: [-h|-H|-D|-P|-p|-d|-s]
options:
-h     Print this help.
-d     Display debug.
-H     ip/dns of current host.
-D     ip/dns of destination host.
-P     protocol ICMP/TCP/UDP.
-p     port
-s     for script output
````
## Functionnalities :

Can check :
- ping (ICMP protocol)
- network flow (via tcpdump) remotely (via ssh)
- tcp/udp protocols (via nc) or remotely (via ssh)


## How to use the map script :
````
 ./mapv2.sh networkV2.template 
````
result :
![image](https://github.com/alexvea/check_network/assets/35368807/fbbc4b04-7433-4129-8c1b-ba2ba83ec5d1)


## How to create you own ascii map : 

Go to this website : https://asciiflow.com/#/

## Not yet functionning : 

- ascii map with more than 2 servers in horizontal way, example :

````
+---------------------------------+                                                                       
|                                 |                                                                       
|  Central=10.25.15.133           |                                                                       
|  Mariadb=10.25.15.133           |                                                                       
|  ServerC=10.25.15.133           |                                                                       
|                                 |                                                                       
|                                 |                                                                       
+---------------------------------+                                                                       
                                                                                                          
                                                                                                        
                                                  +-----------------+     ICMP         +-----------------+
 +--------------------+    TCP:3306               |                 +------------------>                 |
 |                    +--------------------------->                 |                  |                 |
 |                    |    TCP:22                 |                 |                  |                 |
 |                    +--------------------------->   Mariadb       |                  |   Poller        |
 |                    |                           |                 |     UDP:161      |                 |
 |     Central        |    TCP:22                 |                 <------------------+                 |
 |                    <---------------------------+                 |                  |                 |
 |                    |                           |                 |                  |                 |
 |                    |                           +-----------------+                  +-----------------+
 +--------------------+                                                                                   
  ````










