#!/usr/bin/env bash
json_config=$1
#cat $json_config
generated_template=./generated_map.template

st_end_conf_box="+---------------------------------+"
middle_conf_box="|                                 |"
st_end_map_box="+------------------+"
middle_map_box="|                  |"
  arrow_to_dst="+-------------------->"
arrow_from_dst="<--------------------+"

begin_config_part() {
        printf "#template \n"
        printf "\n" 
        printf "$st_end_conf_box \n" 
        printf "$middle_conf_box \n"
}
                                          
end_config_part() {
        printf "$middle_conf_box \n"
        printf "$st_end_conf_box \n"
        printf "\n" 
        printf "\n" 
        printf "\n" 
        printf "\n" 
}

list_server_config_part() {
        while read server;do
                server_name=$(echo "$server" | jq -r .name)
                server_ip=$(echo "$server" | jq -r .ip)
                server_line="| $server_name=$server_ip"
                number_of_caracter_to_add=$((${#middle_conf_box} - ${#server_line}))
                printf '%s%*s \n' "$server_line" "$number_of_caracter_to_add" "|"
        done < <(cat "$json_config" | jq -c '.config[0].servers[]')
}

get_server_name_from_id() {
        servers=$(cat "$json_config" | jq -c '.config[0].servers[]')
        echo "$servers" | jq -r "select(.id==$1) | .name"
}

begin_map_part() {
        printf "#map \n"
        printf "\n"
        local number_of_caracter_to_add=$((${#st_end_map_box} * 2))
        printf '%s%*s \n' "$st_end_map_box" "$number_of_caracter_to_add" "$st_end_map_box"
        printf '%s%*s \n' "$middle_map_box" "$number_of_caracter_to_add" "$middle_map_box"
}

end_map_part() {
        local number_of_caracter_to_add=$((${#st_end_map_box} * 2))
        printf '%s%*s\n' "$middle_map_box" "$number_of_caracter_to_add" "$middle_map_box"
        printf '%s%*s\n' "$st_end_map_box" "$number_of_caracter_to_add" "$st_end_map_box"
}

list_link_part() {
        local number_of_caracter_to_add=$((${#st_end_map_box} * 2))
        #local total_links=$(cat "$json_config" | jq -c '.config[1].links[]' | wc -l)
        local total_links=$(echo $1 | wc -l)
        local half_link=$((($total_links / 2) + ($total_links % 2 > 0)))
        local current_link_number=0
        while read server;do
                ((current_link_number++))
                src_id=$(echo "$server" | jq -r .src_id)
                dst_id=$(echo "$server" | jq -r .dst_id)
                protocol=$(echo "$server" | jq -r .protocol)
                port=$(echo "$server" | jq -r .port)
                protocol_port=$( [ "${protocol^^}" == "ICMP" ] && echo $protocol || echo $protocol:$port )
                [ "$current_link_number" -eq 1 ] && src_name=$(get_server_name_from_id $src_id) && src_id_first_link=$src_id && dst_name=$(get_server_name_from_id $dst_id)
                arrow=$( [ $src_id_first_link -eq $src_id ] && echo $arrow_to_dst || echo $arrow_from_dst )
                printf '%s%*s%*s%*s%*s\n' "|" "$((${#st_end_map_box}-1))" "|" "$((${#st_end_map_box}/2))" "$protocol_port" "$(((${#st_end_map_box}/2)+1))" "|" "$((${#st_end_map_box}-1))" "|"
                printf '%s%*s%*s\n' "|" "$(((${#st_end_map_box})*2))" "$arrow" "$(((${#st_end_map_box}-1)))" "|"
                if [ "$current_link_number" -eq "$half_link" ]; then
                        printf '%s%s%*s%*s%s%*s\n' "|   " "$src_name" "$((${#st_end_map_box}-${#src_name}-4))" "|" "$((${#st_end_map_box}+4))" "|   " "$dst_name" "$((${#st_end_map_box}-${#dst_name}-4))" "|"
                fi
        #done < <(cat "$json_config" | jq -c '.config[1].links[]')
        done < <(echo "$1")
}




begin_config_part
list_server_config_part
end_config_part

begin_map_part
list_link_part "$(cat "$json_config" | jq -c '.config[1].links[]')"
end_map_part
