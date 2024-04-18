#!/usr/bin/env bash
map_path=$1
cat $map_path > $map_path.rt
check_list=$(for host in `grep -E -o '[A-Z]=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' $map_path`; do grep -o -E "${host%=*}--->[A-Z]:(TCP|UDP|ICMP):[0-9]+" $map_path; done)
for check_line in `echo $check_list`; do
        HD=$(echo $check_line | awk -F":" ' { print $1 }')
                HD_converted=$HD
                for host in `grep -E -o '[A-Z]=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' $map_path`;do
                        HD_converted=$(echo $HD_converted | sed "s/${host%=*}/${host##*=}/g")

                done
        PROTOCOL=$(echo $check_line | awk -F":" ' { print $2 }')
        PORT=$(echo $check_line | awk -F":" ' { print $3 }')
        #echo $HD
        #echo ${HD_converted%--->*}
        #echo ${HD_converted##*--->}
        #echo $PROTOCOL
        #echo $PORT
        #echo ${#check_line}
        result_check=$(./ncheck.sh -H ${HD_converted%--->*} -D ${HD_converted##*--->} -P $PROTOCOL -p $PORT)
        sed -i "s~$check_line~$result_check~g" $map_path.rt
                for host in `grep -E -o '[A-Z]=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' $map_path`;do
                        sed -i "11,\$s~${host##*=}~${host%=*}~g" $map_path.rt
                done
done
cat $map_path.rt
