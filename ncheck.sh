#!/usr/bin/env bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "The script will help to check port/network flow and UDP/TCP/ICMP protocol."
   echo "Syntax: [-h|-H|-D|-P|-p|-d]"
   echo "options:"
   echo "-h     Print this help."
   echo "-d     Display debug."
   echo "-H     ip/dns of current host." 
   echo "-D     ip/dns of destination host." 
   echo "-P     protocol ICMP/TCP/UDP."
   echo "-p     port"
   echo
}
set -e
DESTINATION=""
SUDO_CMD="/usr/bin/env sudo -u ssh_user"
SSH_CMD=""
NETSTAT_CMD="/usr/bin/env netstat"
IP_CMD="/usr/bin/env ip a"
AWK_CMD="/usr/bin/env awk"
PING_CMD="/usr/bin/env ping -c 1 -W 1"
NC_CMD="/usr/bin/env nc"

while getopts "hdH:D:P:p:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      d) #display debug
         DEBUG=1
         ;;
      H) #host 
         HOST=("$OPTARG")
         ;;
      D) #destination 
         [[ "$OPTARG" =~ ^(127.0.0.1|localhost)$ ]] && echo "Destination can't be localhost" && exit || DESTINATION=("$OPTARG")
         ;;
      P) #PROTOCOL 
         [[ ! "$OPTARG" =~ ^(ICMP|icmp|TCP|tcp|UDP|udp)$ ]] && echo "Wrong protocol" && exit || PROTOCOL=$(echo $OPTARG | awk '{print tolower($0)}')
         ;;
      p) #PORT
         [[ ! "$OPTARG" =~ ^((6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([0-5]{0,5})|([0-9]{1,4}))$ ]] && echo "Wrong port" && exit || PORT=("$OPTARG")
 
         ;;
     \?) # Invalid option
         exit;;
   esac
done

function check_if_host_is_local {
        [[ $1 =~ ^(127.0.0.1|localhost) ]] && return 0
        OUTPUT=$($IP_CMD | grep $1)
        [[ ! -z $OUTPUT ]] && return 0 || return 1
}

function create_listen_port {
        F_SSH_CMD="$SUDO_CMD ssh ssh_user@$1"
        F_PROTOCOL=$2
        F_PORT=$3
        [[ $DESTINATION == "$(localhost_to_primary_ip)" ]] && F_SSH_CMD="$SUDO_CMD"
        [[ "$F_PROTOCOL" =~ ^(ICMP|icmp)$ ]] && DST_FILTER="$F_PROTOCOL" || DST_FILTER="dst port $F_PORT and $F_PROTOCOL"
        sleep 1 && $SSH_CMD $CHECK_CMD $DESTINATION $PORT 2> /dev/null &
        result=$($F_SSH_CMD sudo tcpdump -c 1 -n src host $HOST and $DST_FILTER 2> /dev/null && echo ok)
        echo $result
}

function localhost_to_primary_ip {
        echo $(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
}

if check_if_host_is_local $HOST; then
        HOST_IS_LOCAL=1
        HOST=$(localhost_to_primary_ip)
else
        HOST_IS_LOCAL=0
        SSH_CMD="$SUDO_CMD ssh ssh_user@$HOST"
fi

#cas check network flow from X to Y
if [[ ! -z $DESTINATION ]] ; then
        case $PROTOCOL in 
                ICMP|icmp)
                #remote 10.25.12.240>10.25.15.133 icmp 
                #sudo -u ssh_user ssh 'ssh_user@10.25.12.240' "ping -c 1 10.25.15.133 &> /dev/null"
                CHECK_CMD="$PING_CMD"
                PORT=""
                ;;
                TCP|tcp)
                #remote 10.25.12.240>10.25.15.133 tcp 22
                # sudo -u ssh_user ssh 'ssh_user@10.25.12.240' "nc -vz 10.25.15.133 22"
                CHECK_CMD="$NC_CMD -vz"
                ;;
                UDP|udp)
                #remote 10.25.12.240>10.25.15.133 udp 161
                # sudo -u ssh_user ssh 'ssh_user@10.25.12.240' "nc -vz -u 10.25.15.133 161"
                CHECK_CMD="$NC_CMD -vz -u"
                ;;
        esac
        $SSH_CMD $CHECK_CMD $DESTINATION $PORT || create_listen_port $DESTINATION $PROTOCOL $PORT
else
        #cas check port remote
        #cas tcp/udp sudo -u ssh_user ssh ssh_user@10.25.12.240 /usr/bin/env netstat -tulan | awk  '$1 ~ "udp" && $4 ~ /(0.0.0.0:68|:::68|10.25.12.240:68)/ && $5 ~ /(0.0.0.0:*|:::*)/'
        [[ "$PROTOCOL" =~ ^(ICMP|icmp)$ ]] && $SSH_CMD $PING_CMD $HOST || $SSH_CMD $NETSTAT_CMD -tulan | $AWK_CMD -v proto="$PROTOCOL" -v host="$HOST" -v port="$PORT"$ '$1 ~ proto && $4 ~ ("0.0.0.0:"port"|:::"port"|"host":"port) && $5 ~ ("0.0.0.0:*|:::*")' 

fi
