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
#set -e
DESTINATION=""
ENV_CMD="/usr/bin/env"
SUDO_CMD="$ENV_CMD sudo -u ssh_user"
SSH_CMD=""
SSH_OPT="-o ConnectTimeout=1"
NETSTAT_CMD="$ENV_CMD netstat"
IP_CMD="$ENV_CMD ip a"
AWK_CMD="$ENV_CMD awk"
PING_CMD="$ENV_CMD ping -c 1 -W 1"
NC_CMD="$ENV_CMD nc"
NC_OPT="-w 0.1"


#color
RED=$'\033[0;31m'
NC=$'\033[0m' # No Color
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
PURPLE=$'\033[0;35m'
WHITE=$'\033[1;37m'

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
        F_SSH_CMD="$SUDO_CMD ssh ssh_user@$1 $SSH_OPT"
        F_PROTOCOL=$2
        F_PORT=$3
        [[ $DESTINATION == "$(localhost_to_primary_ip)" ]] && F_SSH_CMD="$SUDO_CMD"
        [[ "$F_PROTOCOL" =~ ^(ICMP|icmp)$ ]] && DST_FILTER="$F_PROTOCOL" || DST_FILTER="dst port $F_PORT and $F_PROTOCOL"
        sleep 1 && result_tcpdump_network=$($SSH_CMD $CHECK_CMD $DESTINATION $PORT 2>&1 &) &
        result_ssh_connection=$($F_SSH_CMD -v "exit" 2>&1) && result_tcpdump=$(timeout 3 $F_SSH_CMD sudo tcpdump -c 1 -n src host $HOST and $DST_FILTER 2> /dev/null)
        [[ $result_ssh_connection =~ (debug1: Exit status 0) ]] && result_port=`$SSH_CMD $NETSTAT_CMD -tulan | $AWK_CMD -v proto="$PROTOCOL" -v host="$HOST" -v port="$PORT"$ '$1 ~ proto && $4 ~ ("0.0.0.0:"port"|:::"port"|"host":"port) && $5 ~ ("0.0.0.0:*|:::*")'`
}

function localhost_to_primary_ip {
        echo $(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
}

function display_result {
        F_result_network_flow=$1
        F_result_tcpdump=$2
        F_result_port=$3
        F_result_ping=$4
        F_result_ssh_connection=$5
                [[ "$PROTOCOL" =~ ^(ICMP|icmp)$ ]] && PORT="PONG"
                if [[ ! -z $F_result_tcpdump ]] && [[ "$F_result_network_flow" =~ (refused|0 received) ]] ; then
                        ARROW="${GREEN}--->${NC}"
                        PORT_COLOR="${RED}$PORT${NC}"
                elif [[ "$F_result_network_flow" =~ (1 received|Connected to) ]] || [[ "$F_result_ping" =~ (1 received) ]]; then
                        ARROW="${GREEN}--->${NC}"
                        PORT_COLOR="${GREEN}$PORT${NC}"
                elif [[ ! "$F_result_ssh_connection" =~ (debug1: Exit status 0) ]]; then
                        ARROW="${WHITE}-?->${NC}"
                        PORT_COLOR="${RED}$PORT${NC}"
                elif [[ "$F_result_ssh_connection" =~ (debug1: Exit status 0) ]] && [[ ! -z "$F_result_port" ]]; then
                        ARROW="${RED}--->${NC}"
                        PORT_COLOR="${GREEN}$PORT${NC}"
                else
                        ARROW="${RED}--->${NC}"
                        PORT_COLOR="${RED}$PORT${NC}"
                fi
                if [[ ! -z "$DESTINATION" ]]; then
                        DESTINATION_CONTENT=$ARROW$DESTINATION
                else
                        DESTINATION_CONTENT=""
                fi
                PORT_CONTENT=$PORT_COLOR
                echo -e "$HOST$DESTINATION_CONTENT/$PROTOCOL:$PORT_CONTENT"
}

if check_if_host_is_local $HOST; then
        HOST_IS_LOCAL=1
        HOST=$(localhost_to_primary_ip)
else
        HOST_IS_LOCAL=0
        SSH_CMD="$SUDO_CMD ssh ssh_user@$HOST $SSH_OPT"
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
                CHECK_CMD="$NC_CMD -vz $NC_OPT"
                ;;
                UDP|udp)
                #remote 10.25.12.240>10.25.15.133 udp 161
                # sudo -u ssh_user ssh 'ssh_user@10.25.12.240' "nc -vz -u 10.25.15.133 161"
                CHECK_CMD="$NC_CMD -vz -u $NC_OPT"
                ;;
        esac
        result_network_flow=$($SSH_CMD $CHECK_CMD $DESTINATION $PORT 2>&1 ) || create_listen_port $DESTINATION $PROTOCOL $PORT 
else
        #cas check port remote
        #cas tcp/udp sudo -u ssh_user ssh ssh_user@10.25.12.240 /usr/bin/env netstat -tulan | awk  '$1 ~ "udp" && $4 ~ /(0.0.0.0:68|:::68|10.25.12.240:68)/ && $5 ~ /(0.0.0.0:*|:::*)/'
        [[ "$PROTOCOL" =~ ^(ICMP|icmp)$ ]] && result_ping=$($SSH_CMD $PING_CMD $HOST) || result_port=`$SSH_CMD $NETSTAT_CMD -tulan | $AWK_CMD -v proto="$PROTOCOL" -v host="$HOST" -v port="$PORT"$ '$1 ~ proto && $4 ~ ("0.0.0.0:"port"|:::"port"|"host":"port) && $5 ~ ("0.0.0.0:*|:::*")'`

fi
 [[ $DEBUG == 1 ]] && [[ ! -z $result_port ]] && echo "PORT RESULT: " $result_port 
 [[ $DEBUG == 1 ]] && [[ ! -z $result_ping ]] && echo "PING RESULT: " $result_ping 
 [[ $DEBUG == 1 ]] && [[ ! -z $result_ssh_connection ]] && echo "SSH RESULT: "  && echo $result_ssh_connection
 [[ $DEBUG == 1 ]] && [[ ! -z $result_network_flow ]] && echo "NETFLOW RESULT: " $result_network_flow 
 [[ $DEBUG == 1 ]] && [[ ! -z $result_tcpdump ]] && echo "TCPDUMP RESULT: "  $result_tcpdump
display_result "$result_network_flow" "$result_tcpdump" "$result_port" "$result_ping" "$result_ssh_connection"
