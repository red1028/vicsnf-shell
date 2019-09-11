#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)


####################################
## input nfd name and manage network
####################################
read -p "${bold}ICN+DTN Register VNF description and distribute VNF to the system. Do you want to proceed?(n or y[default]) :${normal}" is_process

if [ -z $is_process ]; then
  is_process='y'
fi

if [ "$is_process" = "y" -o "$is_process" = "Y" ]; then

. ~/icn_dtn_topology.inc
base_image_name="$(openstack image list | grep icn_dtn_base_ | awk '/ / {print $4}')"

is_vnfd=($(openstack vnf descriptor list | grep ICN_DTN_VNF | awk '/ / {print $2, $4}'))
if [[ -n $is_vnfd ]]; then
  echo ""
  echo "${bold}Delete the existing VNFD (${is_vnfd[1]})${normal}"
  openstack vnf descriptor delete ${is_vnfd[0]}
fi
echo ""
echo "${bold}Create the VNFD${normal}"
openstack vnf descriptor create --vnfd-file ~/01_ICN_DTN_VNFD.yaml ICN_DTN_VNF
sleep 2

for key in ${!vnf_names[@]}
do
cat <<EOF | tee ~/${vnf_names[$key]}_param.yaml >/dev/null
{
 vnf_name: '${vnf_names[$key]}',
 base_image_name: '$base_image_name',
 zone_name: '${zone_names[$key]}',
 vnf_mgmt_ip: '${vnf_mgmt_ips[$key]}',
 vnf_top_ip: '${vnf_top_ips[$key]}',
 vnf_bottom_ip: '${vnf_bottom_ips[$key]}',
 vnf_top_vl: '${vnf_top_vls[$key]}',
 vnf_bottom_vl: '${vnf_bottom_vls[$key]}'
}
EOF

  echo ""
  echo "${bold}The work for ${vnf_names[$key]} deployment begins.${normal}"
  sleep 1

  ####################################
  ## Connect VNF and NFD install process 
  ####################################
  is_vnf=$(openstack vnf list | grep ${vnf_names[$key]}_vnf | awk '/ / {print $2}')
  create_vnf_name=${vnf_names[$key]}_vnf

  if [[ -n $is_vnf ]]; then
    echo ""
    read -p "${bold}${vnf_names[$key]}_vnf already exists. Are you sure you want to delete?(n or y[default]) : ${normal}" is_delete
    if [[ -z $is_delete ]]; then
      is_delete='y'
    fi

    if [[ $is_delete = 'y' ]]; then
      openstack vnf delete ${vnf_names[$key]}_vnf
      echo ""
      echo "${bold}${vnf_names[$key]}_vnf is being deleted.${normal}"
      for (( ; ; ))
      do
        is_delete_ok=$(openstack vnf list | grep ${vnf_names[$key]}_vnf | awk '/ / {print $2}')
        if [[ -z $is_delete_ok ]]; then
          echo ""
          echo "${bold}${vnf_names[$key]}_vnf is deleted${normal}"
          break
        fi
        sleep 1
      done
    else
      create_vnf_name=${vnf_names[$key]}_vnf_1
    fi
  fi

  ####################################
  ## Create VNF
  ####################################
  echo ""
  echo "${bold}Create the ${vnf_names[$key]}.${normal}"
  openstack vnf create --vim-name ICN_DTN_VIM --vnfd-name ICN_DTN_VNF --param-file ~/${vnf_names[$key]}_param.yaml $create_vnf_name

  if [ $key -eq 1 ]; then
    start_time="$(date -u +%s)"
  fi

#  ####################################
#  ## Check VNF status
#  ####################################
#  echo ""
#  prev_status=""
#  start_time="$(date -u +%s)"
#  for (( ; ; ))
#  do
#    is_active=$(openstack server list | grep ${vnf_names[$key]} | awk '/ / {print $6}')
#    if [[ $prev_status = 'NOTYET' ]]; then
#      start_time="$(date -u +%s)"
#    fi
#
#    if [[ "$is_active" = "ACTIVE" ]]; then
#      end_time="$(date -u +%s)"
#      break
#    elif [[ -z $is_active ]]; then
#      start_time="$(date -u +%s)"
#      is_active='NOTYET'
#    fi
#    if [[ $is_active != "$prev_status" ]]; then
#           prev_status="$is_active"
#      end_time="$(date -u +%s)"
#      elapsed="$(($end_time-$start_time))"
#      echo "The ${vnf_names[$key]} initiation elapsed time: $is_active, $elapsed(s)"
#    fi
#  done
#  elapsed="$(($end_time-$start_time))"
#  echo "${bold}The ${vnf_names[$key]} initiation elapsed time: $is_active, $elapsed(s)${normal}"

done

####################################
## Check VNF status
####################################
echo ""
#start_time="$(date -u +%s)"
start_time=$(($start_time-9))
for i in {1..100}
do
  is_active=$(openstack server list | grep ICNDTN_ | awk '/ / {print $6}')
  is_active_cnt=$(echo $is_active | grep -o ACTIVE | wc -l)

  if [[ $is_active_cnt -eq ${#vnf_names[@]} ]]; then
    end_time="$(date -u +%s)"
    break;
  fi

  end_time="$(date -u +%s)"
  elapsed="$(($end_time-$start_time))"
  echo "The Demo ICN+DTN VNF all initiation elapsed time:"
  echo "  total_active_cnt=${#vnf_names[@]}, curr_active_cnt=$is_active_cnt, $elapsed(s)"
done
elapsed="$(($end_time+3-$start_time))"
one_vnf_elapsed=$(($elapsed/${#vnf_names[@]}))
echo "${bold}The Demo ICN+DTN VNFD : 3(s)${normal}"
echo "${bold}The Demo ICN+DTN VNF all initiation elapsed time: $elapsed(s), 1 VNF about $one_vnf_elapsed(s)${normal}"

fi
