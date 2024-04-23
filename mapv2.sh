#!/usr/bin/env bash
# Function to execute ncheck command and update result in the network map
PROTOCOL_PORT_REGEX='(TCP|UDP):+[0-9]+|ICMP'
execute_ncheck() {
    local ncheck_command="$1"
    local result_protocolport_line_number="$2"
    local network_map_file="$3"

        # Execute ncheck command and update result in the network map
        ncheck_result=$(eval "$ncheck_command")
        # If debug mode is enabled, echo the ncheck result
        if [ "$DEBUG_MODE" = true ]; then
            echo "DEBUG: $ncheck_command"
            echo "DEBUG: ncheck result: $ncheck_result"
        fi
        # Extract network flow and port status from ncheck_result
        network_flow_status=$(echo "$ncheck_result" | awk -F '/' '{print $1}')
        port_status=$(echo "$ncheck_result" | awk -F '/' '{print $2}')
        # Update ASCII map based on network flow and port status
        [[ $protocol =~ ICMP ]] && updated_segment=$(colorize_check_result "$line" "$port_status" "$protocol") || updated_segment=$(colorize_check_result "$line" "$port_status" "$protocol:$port")
        updated_segment_second=$(colorize_check_result "$second_line" "$network_flow_status" "$arrow")

        # Update the line with the updated segment and write it back to the ASCII map
        updated_protocolport_line=$(echo "${updated_segment#*:}")
        updated_connection_line=$(echo "${updated_segment_second#*-}")
        result_connection_line_number=$(expr ${result_protocolport_line_number} + 1)
        sed  -i "${result_protocolport_line_number}s/.*/${updated_protocolport_line}/" $network_map_file2
        sed  -i "${result_connection_line_number}s/.*/${updated_connection_line}/" $network_map_file2
}
function get_host_ip() {
        local host=$1
        host_ip=$(grep -w "$host" "$network_map_file" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        echo $host_ip
}
function get_host_from_map() {
        local check_line=$1
        local line_number=${check_line%%:*}
        local HOST_POS=""
        line_number_up=$line_number
        line_number_down=$line_number
        PROTO_PORT_POS=${check_line#*$protocol}
        while [[ "$line_number_up" -gt 6 ]] || [[ -z "HOST_H" && -z "$HOST_D" ]]; do
        for host in $hosts; do
                local HOST=${host%%=*}
                host_line=$(sed "$line_number_up","$line_number_down"'!d' $network_map_file | grep -n ${HOST})
                [[ ! -z $host_line ]] && HOST_POS=${host_line#*$HOST}
                [[ ${#HOST_POS} -ne 0 ]] && [[ ${#HOST_POS} -gt ${#PROTO_PORT_POS} ]] && [[ -z $HOST_H ]] && HOST_H=${HOST} && host_line="" && HOST_POS=""
                [[ ${#HOST_POS} -ne 0 ]] && [[ ${#HOST_POS} -lt ${#PROTO_PORT_POS} ]] && [[ -z $HOST_D ]] && HOST_D=${HOST} && host_line="" && HOST_POS=""
        done
                line_number_up=$((line_number_up-1))
                line_number_down=$((line_number_down+2))
        done
                host_options="-H \"$(get_host_ip $HOST_H)\" -D \"$(get_host_ip $HOST_D)\""
                [[ $arrow_index == "<"  ]] && host_options="-D \"$(get_host_ip $HOST_H)\" -H \"$(get_host_ip $HOST_D)\"" 
                # Form ncheck command with IP addresses
                ncheck_command="./ncheck.sh -s $host_options -P \"$protocol\" -p \"$port\""
                # Execute ncheck command and update result in the network map
                line_number_up=""
                line_number_down=""
                HOST_POS=""
                HOST_H=""
                HOST_D=""
}

# Function to parse ASCII network map and extract connections with coordinates
parse_network_map() {
    local network_map_file="$1"
    local connections=$(grep -E 'TCP|UDP|ICMP' -A1 -n "$network_map_file" | grep -v "^--$")
    # Extract source and destination host names from the top of the map
    local hosts=$(awk '/^[+|].*[A-Za-z]/ && NR<=10 {print $2}' "$network_map_file")
    # Extract connections, coordinates, and associated protocols/ports
        while read line; read second_line; do
        if [[ $line =~ "TCP" || $line =~ "UDP" || $line =~ "ICMP" ]]; then
            # Extract protocol, port, and arrow direction from the line
            protocols_ports=($(echo "$line" | grep -oP $PROTOCOL_PORT_REGEX))
            arrow_position=$(expr index "$second_line" "<\+>")
            arrow_index=$(echo "$second_line" | grep -o "[<>]")
            arrow=$(echo "$second_line" | grep -oE "[<>\+]-*[<>\+]")
            # Split the line into segments based on the arrow position
            segments=()
            if [[ $arrow_index == "<" ]]; then
                segments+=("$(echo "$line" | awk -v pos="$arrow_position" '{print substr($0, pos)}')")
                segments+=("$(echo "$line" | awk -v pos="$arrow_position" '{print substr($0, 1, pos-1)}')")
            else
                segments+=("$(echo "$line" | awk -v pos="$arrow_position" '{print substr($0, 1, pos)}')")
                segments+=("$(echo "$line" | awk -v pos="$arrow_position" '{print substr($0, pos+1)}')")
            fi
            # Iterate over each segment and update protocol/port pairs
            for segment in "${segments[@]}"; do
                # Check if the segment contains any protocol/port pairs
                if [[ $segment =~ $PROTOCOL_PORT_REGEX ]]; then
                    # Extract protocol/port pairs from the segment
                    protocols_ports=($(echo "$segment" | grep -oP $PROTOCOL_PORT_REGEX))
                    # Iterate over each protocol/port pair and process it
                    for protocol_port in "${protocols_ports[@]}"; do
                        #protocol=$(echo "$protocol_port" | awk -F":" '{print $1}')
                        protocol=$(echo "$protocol_port" | grep -oP '(TCP|UDP|ICMP)')
                        port=$(echo "$protocol_port" | awk -F":" '{print $2}')
                        get_host_from_map "$line"
                        result_line_number=$(echo "$line" | cut -d: -f1)
                        execute_ncheck "$ncheck_command" "$result_line_number" "$network_map_file"
                    done
                else
                    updated_segments+=("$segment")
                fi
            done
        fi
    done <<< "$connections"
}

# Function to colorize the check result and return the updated segment
colorize_check_result() {
    local segment=$1
    local result=$2
    local value=$3
    local color_code
    local WHITE=$'\033[1;37m'
    # Set color code based on the result
    if [[ $result == "OK" ]]; then
        color_code=$'\033[0;32m'  # Green color for success
    elif [[ $result == "NOK" ]]; then
        color_code=$'\033[0;31m'  # Red color for failure
    else
        color_code=$'\033[1;30m'  # Grey color for unknown
    fi
    # Colorize the protocol/port or connection
    local colored_value="${color_code}$value"
    # Return the updated segment with colorized elements
    echo "$(echo "$segment" | sed "s/\($value\)/$colored_value${WHITE}/")"
}

# Main script starts here
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <network_map_file> [-d]"
    exit 1
fi

network_map_file=$1
network_map_file2=$network_map_file".modified"
cp $network_map_file  $network_map_file2
sed -i "s/#template/#real-time/g" $network_map_file2
# Check if debug mode is enabled
if [[ $2 == "-d" ]]; then
    DEBUG_MODE=true
fi

# Parse the ASCII network map and execute ncheck commands
parse_network_map "$network_map_file" &
watch -t -n 1 -c cat $network_map_file".modified"
