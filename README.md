# check_network

## Description :
Theses bash scripts will allow to check the protocol/port and network flow on a ascii map.

## Prerequisites :
create an linux user called ssh_user on current server and remote server
install a SSH key to authenticate as ssh_user, to be able to connect like :
````
sudo -u ssh_user ssh ssh_user@remote_server 
````
you can use this script to generate and install the ssh key to remote server : 
https://github.com/centic9/generate-and-send-ssh-key

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

1)Go to this website : https://asciiflow.com/#/

2)Or, use generate_map.sh with a map.json :

map.json
````
{
  "config": [
    {
      "servers": [
        {
          "id": 1,
          "name": "Central",
          "ip": "10.25.15.133"
        },
        {
          "id": 2,
          "name": "Docker",
          "ip": "10.25.15.161"
        },
        {
          "id": 3,
          "name": "MBI",
          "ip": "10.25.12.240"
        }
      ]
    },
    {
      "links": [
        {
          "src_id": 1,
          "dst_id": 2,
          "protocol": "UDP",
          "port": "161"
        },
        {
          "src_id": 1,
          "dst_id": 2,
          "protocol": "TCP",
          "port": "9443"
        },
        {
          "src_id": 1,
          "dst_id": 2,
          "protocol": "TCP",
          "port": "8025"
        },
        {
          "src_id": 1,
          "dst_id": 2,
          "protocol": "ICMP",
          "port": null
        },
        {
          "src_id": 1,
          "dst_id": 3,
          "protocol": "TCP",
          "port": "1234"
        },
        {
          "src_id": 3,
          "dst_id": 1,
          "protocol": "TCP",
          "port": "22"
        }
      ]
    }
  ]
}
````

````
./generate_map.sh map.json
````
result :
````
#template 
+---------------------------------+ 
| Central=10.25.15.133            | 
| Docker=10.25.15.161             | 
| MBI=10.25.12.240                | 
+---------------------------------+ 

#map 
+------------------+                    +------------------+ 
|                  |   UDP:161          |                  |
|                  +-------------------->                  |
|                  |  TCP:9443          |                  |
|                  +-------------------->                  |
|   Central        |                    |   Docker         |
|                  |  TCP:8025          |                  |
|                  +-------------------->                  |
|                  |      ICMP          |                  |
|                  +-------------------->                  |
+------------------+                    +------------------+
+------------------+                    +------------------+ 
|                  |  TCP:1234          |                  |
|                  +-------------------->                  |
|   Central        |                    |   MBI            |
|                  |    TCP:22          |                  |
|                  <--------------------+                  |
+------------------+                    +------------------+
````
## Not yet functionning : 

- ascii map with more than 2 servers in horizontal way, example :

````
+---------------------------------+                                                                       
|                                 |                                                                       
|  ServerA=IP_A                   |                                                                       
|  ServerB=IP_B                   |                                                                       
|  ServerC=IP_C                   |                                                                       
|                                 |                                                                       
|                                 |                                                                       
+---------------------------------+                                                                       
                                                                                                          
                                                                                                        
                                                  +-----------------+     ICMP         +-----------------+
 +--------------------+    TCP:3306               |                 +------------------>                 |
 |                    +--------------------------->                 |                  |                 |
 |                    |    TCP:22                 |                 |                  |                 |
 |                    +--------------------------->   ServerB       |                  |   ServerC       |
 |                    |                           |                 |     UDP:161      |                 |
 |     ServerA        |    TCP:22                 |                 <------------------+                 |
 |                    <---------------------------+                 |                  |                 |
 |                    |                           |                 |                  |                 |
 |                    |                           +-----------------+                  +-----------------+
 +--------------------+                                                                                   
  ````










