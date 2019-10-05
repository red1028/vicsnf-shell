#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)


####################################
## input nfd name and manage network
####################################
echo ""
read -p "${bold}Do you want to proceed with setting up the ICN route path between C-VNF to C-VNF?(n or y[default]) :${normal}" is_process
read -p "${bold}Do you want to proceed with deletion only?(y or n[default]) :${normal}" c_vfn_delete

if [ -z $is_process ]; then
  is_process='y'
fi
if [ -z $c_vfn_delete ]; then
  c_vfn_delete='n'
fi

if [ "$is_process" = "y" -o "$is_process" = "Y" ]; then
  pushd ./pod/vicsnf
  c_vnf_names=("vnf1-route" "vnf2-route")
  vnf_total_cnt=0
  vnf_list_str=""
  vnf_create_str="kubectl create"
  vnf_delete_str=""
  for vnf_name in ${c_vnf_names[@]}
  do
    is_c_vnf=$(kubectl get pods --all-namespaces | grep -o $vnf_name | grep -v NAME | wc -l)
    if [ $is_c_vnf -gt 0 ]; then
      vnf_delete_str="$vnf_delete_str $vnf_name"
    fi	
    vnf_total_cnt=$((vnf_total_cnt + 1))
    vnf_list_str="$vnf_list_str $vnf_name"
    vnf_create_str="$vnf_create_str -f $vnf_name.yaml"
  done
     
  if [ "$vnf_delete_str" != "" ]; then
    kubectl -n vicsnet delete pod $vnf_delete_str
    sleep 10
  fi
  
  if [ $c_vfn_delete == 'y' ]; then
    echo "${bold}C-VNF deletion has been completed.${normal}"
    exit 0
  fi
  
  echo ""
  echo "${bold} == Create ICN+DTM C-VNFs == ${normal}"
  $vnf_create_str
  sleep 2
  
  start_time="$(date -u +%s)"
  for i in {1..500}
  do
    is_running_cnt=$(kubectl -n vicsnet get pods ${c_vnf_names[@]} | grep -v 'NAME' | grep -o Running | wc -l)
    end_time="$(date -u +%s)"
    elapsed="$(($end_time-$start_time))"
    
    if [[ "$vnf_total_cnt" -eq "$is_running_cnt" ]]; then
      echo "The ICN+DTN CVNF(total_vnf: $vnf_total_cnt, running_vnf: $is_running_cnt) elapsed time : $elapsed(s)"			
      break;
    fi
  
    echo "The ICN+DTN CVNF(total_vnf: $vnf_total_cnt, running_vnf: $is_running_cnt) elapsed time : $elapsed(s)"
    sleep 1
  done
  
  if [[ "$vnf_total_cnt" -eq "$is_running_cnt" ]]; then
    echo ""
    echo "${bold}Start routing test (${c_vnf_names[0]} and ${c_vnf_names[1]})${normal}"	  
    start_time="$(date -u +%s)"		
    kubectl -n vicsnet exec -it ${c_vnf_names[0]} \
    env C_VNF_NAME_1=${c_vnf_names[0]} \
    env C_VNF_NAME_2=${c_vnf_names[1]} \
    env NDNPING_PREFIX="/ndn/route1/test/ping" \
    -- /bin/bash -c \
'
echo -e "\033[1m Connected $C_VNF_NAME_1 \033[0m"
ndnping_prefix=$NDNPING_PREFIX
pid=$(ps -ef | grep ndnpingserver | grep -v grep | awk "{ print \$2 }")
if [ "$pid" != "" ]; then
  kill -9 $pid
fi
sleep 1

echo -e "\033[1m  1. Waiting for configuration by cold-start of $C_VNF_NAME_1 VNF\033[0m"
for i in {1..100}
do
  pid=$(ps -ef | grep "\/usr\/local\/bin\/nfd" | grep -v grep | awk "{ print \$2 }")
  if [ "$pid" != "" ]; then
    for i in {1..100}
    do
      sleep 2
      is_nfd=$(nfdc fib list | grep -v grep | grep faceid=1 | wc -l 2> /dev/null)
      if [ $is_nfd -gt 0 ]; then
        sleep 1
        echo -e "\033[1m  1.1. Starting ndnpingserver at $C_VNF_NAME_1 :\033[0m prefix => $ndnping_prefix"
        nohup ndnpingserver $ndnping_prefix > ndnpingserver.out 2> ndnpingserver.err < /dev/null &
        sleep 1
        echo -e "\033[1m  1.2. precess => $(ps -ax | grep ndnpingserver | grep -v grep)\033[0m"
        break
      fi
    done
    break
  else
    cd /root
    rm -f env_original
    ./start_vicsnf.sh
  fi
  sleep 2
done
'
    echo ""
    kubectl -n vicsnet exec -it ${c_vnf_names[1]} \
    env C_VNF_NAME_1=${c_vnf_names[0]} \
    env C_VNF_NAME_2=${c_vnf_names[1]} \
    env NDNPING_PREFIX="/ndn/route1/test/ping" \
    -- /bin/bash -c \
'
echo -e "\033[1m Connected $C_VNF_NAME_2 \033[0m"
ndnping_prefix=$NDNPING_PREFIX

for i in {1..100}
do
  pid=$(ps -ef | grep "\/usr\/local\/bin\/nfd" | grep -v grep | awk "{ print \$2 }")
  if [ "$pid" != "" ]; then
    for i in {1..100}
    do
      sleep 2
      is_nfd=$(nfdc fib list | grep -v grep | grep faceid=1 | wc -l 2> /dev/null)
	  
      if [ $is_nfd -gt 0 ]; then
	    #echo "nfdc route add prefix $ndnping_prefix nexthop udp://$C_VNF_NAME_1"
	    nfdc face create remote udp://$C_VNF_NAME_1
	    nfdc route add prefix $ndnping_prefix nexthop udp://$C_VNF_NAME_1
        break
      fi
    done
    break
  else
    cd /root
    rm -f env_original
    ./start_vicsnf.sh  
  fi
  sleep 2
done

for i in {1..10}
do
  ndn_ping_data=$(ndnping "$ndnping_prefix" | head -n 2 | grep -v PING)
  is_ping=$(echo $ndn_ping_data | grep content | wc -l)
  
  echo ""
  if [ $is_ping -gt 0 ]; then
    echo -e "\033[1m  2. Connect from $C_VNF_NAME_2 to $C_VNF_NAME_1 VNF by ndn ping :\033[0m $ndn_ping_data"
    break;
  else
    echo -e "\033[1m  2. Connect from $C_VNF_NAME_2 to $C_VNF_NAME_1 VNF by ndn ping :\033[0m $ndn_ping_data"
  fi
  sleep 2
done # in {1..100}
'
    end_time="$(date -u +%s)"
    r_elapsed="$(($end_time-$start_time))"

#      kubectl -n vicsnet exec -it ${c_vnf_names[0]} -- /bin/bash -c \
#'
#pid=$(ps -ef | grep ndnpingserver | grep -v grep | awk "{ print \$2 }")
#if [ "$pid" != "" ]; then
#  kill -9 $pid
#fi
#'	
  fi # Routing testing

  echo ""
  echo "${bold}The ICN+DTN CVNF routing time : $r_elapsed(s)${normal}"
	
  popd
fi
