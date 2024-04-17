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
DESTINATION=""
SSH_CMD=""
NETSTAT_CMD="/usr/bin/env netstat"
IP_CMD="/usr/bin/env ip"
AWK_CMD="/usr/bin/env awk"
PING_CMD="/usr/bin/env ping"
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
      D) #host 
         DESTINATION=("$OPTARG")
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
        OUTPUT=$($IP_CMD a | grep $1)
        [[ ! -z $OUTPUT ]] && return 0 || return 1
}

function check_network_flow {
        [[ ! -z $1 ]] && return 0 || return 1
}

function check_listen_port {
        SSH_CMD="sudo -u ssh_user ssh ssh_user@$1"
        #$SSH_CMD $NETSTAT_CMD -tulan | grep $PROTOCOL | egrep "(0.0.0.0:|:::|$HOST:)" | egrep ":$PORT\s" | grep LISTEN
        $SSH_CMD $NETSTAT_CMD -tulan | grep $2 | egrep "(0.0.0.0:|:::|$1:)" | egrep ":$3\s" && return 0 || return 1
}

function create_listen_post {
        F_SSH_CMD="sudo -u ssh_user ssh ssh_user@$1"
        F_PROTOCOL=$2
        F_PORT=$3
        [[ $F_PROTOCOL =~ ^(UDP|udp)$ ]] && F_NC_OPTS="-u"
        $F_SSH_CMD nc -l $F_NC_OPTS $F_PORT
}

if check_if_host_is_local $HOST; then
        HOST_IS_LOCAL=1
else
        HOST_IS_LOCAL=0
        SSH_CMD="sudo -u ssh_user ssh ssh_user@$HOST"
fi


#cas check network flow from X to Y
if check_network_flow $DESTINATION ; then
        case $PROTOCOL in 
                ICMP|icmp)
                #remote 10.25.12.240>10.25.15.133 icmp 
                #sudo -u ssh_user ssh 'ssh_user@10.25.12.240' "ping -c 1 10.25.15.133 &> /dev/null"
                CHECK_CMD="$PING_CMD -c 1"
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
        check_listen_port $DESTINATION $PROTOCOL $PORT && $SSH_CMD $CHECK_CMD $DESTINATION $PORT || echo create_listen_post $DESTINATION $PROTOCOL $PORT
        else
        #cas check port remote
        #cas tcp/udp sudo -u ssh_user ssh ssh_user@10.25.12.240 /usr/bin/env netstat -tulan | awk  '$1 ~ "udp" && $4 ~ /(0.0.0.0:68|:::68|10.25.12.240:68)/ && $5 ~ /(0.0.0.0:*|:::*)/'
        [[ "$PROTOCOL" =~ ^(ICMP|icmp)$ ]] && $SSH_CMD $PING_CMD -c 1 $HOST || $SSH_CMD $NETSTAT_CMD -tulan | $AWK_CMD -v proto="$PROTOCOL" -v host="$HOST" -v port="$PORT"$ '$1 ~ proto && $4 ~ ("0.0.0.0:"port"|:::"port"|"host":"port) && $5 ~ ("0.0.0.0:*|:::*")' 

fi
