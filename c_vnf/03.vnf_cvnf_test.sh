#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

FIXED_IP=192.168.100.222

####################################
## VM and Container ICN+DTN Network Test
####################################
echo ""
read -p "${bold}ICN+DTN message transfer test between VM and Container?(n or y[default]) :${normal}" is_process

if [ -z $is_process ]; then
  is_process='y'
fi

if [ "$is_process" = "y" -o "$is_process" = "Y" ]; then

  echo ""
  echo "${bold}#####################################################"
  echo "## Delete ICN+DTN VNF or C-VNF"
  echo "#####################################################${normal}"

  is_c_vnf=$(kubectl -n vicsnet get pods | grep c-vnf | wc -l)  
  if [ $is_c_vnf -gt '0' ]; then
    kubectl -n vicsnet delete pod c-vnf
    echo "${bold}C-VNF deletion has been completed.${normal}"
    sleep 2
  fi

  is_vm_vnf=$(openstack server list | grep vm-vnf | wc -l)
  if [ $is_vm_vnf -gt '0' ]; then
    openstack server delete vm-vnf
    echo "${bold}VM-VNF deletion has been completed.${normal}"
    sleep 2
  fi

  echo ""
  echo "${bold} == Create ICN+DTM C-VNF == ${normal}"
  kubectl -n vicsnet create -f c-vnf.yaml
  
  echo ""
  echo "${bold} == Create ICN+DTM VM-VNF == ${normal}" 
  openstack server create \
  --image icn-dtn-base-vnc-0.6.5 \
  --flavor ds4G \
  --user-data ./vm-vnf.yaml \
  --availability-zone  nova:vicsnet-core1 \
  --nic net-id=$(openstack network list | awk '/ public / {print $2}'),v4-fixed-ip=$FIXED_IP \
  vm-vnf

  ####################################
  ## Check VM-VNF Active status
  ####################################
  echo ""
  echo "${bold}Check active status for ICN+DTN VM-VNF${normal}"
  start_time="$(date -u +%s)"
  for i in {1..200}
  do
    #is_active=$(openstack server list | grep $name | awk '/ ACTIVE / {print $6}')
    is_active=$(openstack server list | grep vm-vnf | awk '/ / {print $6}')
    if [[ "$is_active" = "ACTIVE" ]]; then 
      end_time="$(date -u +%s)"
      break
    fi
    end_time="$(date -u +%s)"
    elapsed="$(($end_time-$start_time))"
    echo "VM Initiation Elapsed Time: $is_active, $elapsed(s)"
  done
  elapsed="$(($end_time-$start_time))"
  echo "${bold}VM Initiation Elapsed Time: $is_active, $elapsed(s)${normal}"
  sleep 2
  #openstack server reboot --hard vm-vnf
  
  ####################################
  ## Check VM-VNF connect status
  ####################################
  echo ""
  echo "${bold}Check connection status for ICN+DTN VM-VNF${normal}"
  #mgmt_ip=$(openstack server list | grep vm-vnf | awk -F"public=" '{print $2}' | awk '{print $1}')
  mgmt_ip=$FIXED_IP
  for i in {1..200}
  do
    echo "Check ssh port at $mgmt_ip"
    is_ssh=$(nc -z -v $mgmt_ip ssh 2>&1)
    is_ssh=$(echo $is_ssh | grep succeeded! | wc -l)
    if [[ $is_ssh -eq 1 ]]; then
	  echo ""
	  echo "${bold}OK ssh port open${normal}"
      break
    fi
    sleep 2
  done


  ####################################
  ## Check C-VNF connect status
  ####################################
  echo ""
  echo "${bold}Check running status for ICN+DTN C-VNF${normal}"
  vnf_status_pre=""
  for i in {1..100}
  do
	vnf_status=$(kubectl -n vicsnet get pods c-vnf | grep c-vnf | awk '/  / {print $3}')
  
	if [ "$vnf_status_pre" != "$vnf_status" ]; then
		echo "c-vnd-name: c-vnf, status: ${bold}$vnf_status${normal}"
	fi
	if [[ $vnf_status == "Running" ]]; then
	  break;
	fi
	sleep 1
	vnf_status_pre=$vnf_status
  done # in {1..100}
  
  #startTime=$(kubectl -n vicsnet get pods $c_vfn_name -o jsonpath='{.status.startTime}')
  #startedAt=$(kubectl -n vicsnet get pods $c_vfn_name -o jsonpath='{.status.containerStatuses[*]...startedAt}')
  start_end=$(kubectl -n vicsnet get pods c-vnf -o jsonpath='{.status.startTime}|{.status.containerStatuses[*]...startedAt}')
  start_end_arry=(${start_end//|/ })
  
  echo ""
  echo "startTime: ${start_end_arry[0]}"
  echo "startedAt: ${start_end_arry[1]}"
  
  start_time="$(date -d"${start_end_arry[0]}" +%s)"
  end_time="$(date -d"${start_end_arry[1]}" +%s)"
  elapsed="$(($end_time-$start_time))"
  
  echo ""
  echo "${bold}The ICN+DTN C-VNF(c-vnf) creation time : $elapsed(s)${normal}"

  sleep 1
  echo ""
  echo "${bold}Connect VM-VNF${normal}"
  rm -f /root/.ssh/known_hosts
  ndnping_prefix="/ndn/vm/headquarter/ping"
  ssh -o StrictHostKeyChecking=no root@$FIXED_IP \
  export ndnping_prefix="$ndnping_prefix" \
'
pid=$(ps -ef | grep ndnpingserver | grep -v grep | awk "{ print \$2 }")
if [ "$pid" != "" ]; then
  kill -9 $pid
fi
sleep 2

echo -e "\033[1m  Waiting for configuration by cold-start of ICN+DTN router\033[0m"
for i in {1..100}
do
  pid=$(ps -ef | grep "nlsr\ " | grep -v grep | awk "{ print \$2 }")
  if [ "$pid" != "" ]; then
    for i in {1..100}
    do
      sleep 1
      is_nlsr=$(nlsrc routing | grep -v grep | grep NexthopList | wc -l)
      if [ $is_nlsr -gt 0 ]; then
        echo -e "\033[1m  Starting ndnpingserver :\033[0m prefix => $ndnping_prefix"
        ndnpingserver $ndnping_prefix 1> ndnpingserver.out 2>&1 &
        #nohup ndnpingserver $ndnping_prefix > ndnpingserver.out 2> ndnpingserver.err < /dev/null &
        break
      fi
    done
    break
  fi
  sleep 1
done
'

  sleep 1
  echo ""
  echo "${bold}Connect Container-VNF${normal}"
  kubectl -n vicsnet exec -it c-vnf -- /bin/bash -c \
'
ndnping_prefix="/ndn/vm/headquarter/ping"
for i in {1..100}
do
  ndn_ping_data=$(ndnping "/ndn/vm/headquarter/ping" | head -n 2 | grep -v PING)
  ping_data=$(ping -c 1 vm-vnf | grep "from vm-vnf")
  is_ping=$(echo $ndn_ping_data | grep content | wc -l)  

  echo -e "\033[1m  Connection by ping :\033[0m $ping_data"
  if [ $is_ping -gt 0 ]; then
    echo -e "\033[1m  Connection success by ndn ping :\033[0m $ndn_ping_data"
    break;
  else
    echo -e "\033[1m  Connection fail by ndn ping :\033[0m $ndn_ping_data"
  fi
  sleep 1
done # in {1..100}
'
  echo ""
  echo "${bold}Finished ndn messages test between VM and Container${normal}"
fi
