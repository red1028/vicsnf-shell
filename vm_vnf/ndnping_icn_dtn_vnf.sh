#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

echo ""
read -p "${bold}Do you want to check if ICN + DTN VNF is working normally through ndnping test?(n or y[default]) :${normal}" is_process
if [ -z $is_process ]; then
  is_process='y'
fi
if [ "$is_process" = "y" -o "$is_process" = "Y" ]; then

  . ~/icn_dtn_topology.inc

  ####################################
  ##  Name-based PING test
  ####################################
  echo ""
  echo ""
  echo "${bold}#####################################################"
  echo "## Name-based Ping and Publish/Subscribe test."
  echo "#####################################################${normal}"
  sleep 4
  for key in ${!vnf_names[@]}
  do
    ssh -o StrictHostKeyChecking=no root@${vnf_mgmt_ips[$key]} \
export vnf_alias=${vnf_aliases[$key]} \
export vnf_prefix=${vnf_prefixes[$key]} \
export vnf_mgmt_ip=${vnf_mgmt_ips[$key]} \
'
vnf_prefixes=(${vnf_prefix//:/ })

pid=`ps -ef | grep ndnpingserver | grep -v grep | wc -l`
if [[ "$pid" -ne 0 ]]; then
  kill -9 $pid
fi
ping_prefix=${vnf_prefixes[0]}
echo ""
echo -e "\033[1m[$vnf_alias]Running the Name-based ping server.\033[0m"
echo -e "\033[1m  prefix==>ndn:/ndn/${ping_prefix//\\/}\033[0m"
ndnpingserver -t ndn:/ndn/${ping_prefix//\\/} 1> ndnpingserver.out 2>&1 &
echo =============================================================================================
echo "$vnf_alias($vnf_mgmt_ip) [$(ps -ax | grep -v grep | grep ndnpingserver)]"
echo =============================================================================================
sleep 1

pid=`ps -ef | grep ndnpoke | grep -v grep | wc -l`
if [[ "$pid" -ne 0 ]]; then
  kill -9 $pid
fi
echo ""
echo -e "\033[1m[$vnf_alias]Running the Publisher server.\033[0m"
echo -e "\033[1m  prefix==>ndn:/ndn/${ping_prefix//\\/}\033[0m"
echo "Publish Data response from $vnf_alias VNF" | ndnpoke -w 100000 ndn:/ndn/${ping_prefix//\\/} 1> ndnpoke.out 2>&1 &
echo =============================================================================================
echo "$vnf_alias($vnf_mgmt_ip) [$(ps -ax | grep -v grep | grep ndnpoke)]"
echo =============================================================================================
sleep 1
'
  done

  sleep 2
  vnf_cnt=${#vnf_mgmt_ips[@]}
  ndntest_vnf=${vnf_aliases[$((vnf_cnt-1))]}
  echo ""
  echo ""
  echo -e "\033[1mConnecting... $ndntest_vnf(${vnf_mgmt_ips[$((vnf_cnt-1))]}).\033"
  sleep 2

  ssh -o StrictHostKeyChecking=no root@${vnf_mgmt_ips[$((vnf_cnt-1))]} \
export vnf_aliases="'${vnf_aliases[@]}'" \
export vnf_mgmt_ips="'${vnf_mgmt_ips[@]}'" \
export vnf_prefixes="'${vnf_prefixes[@]}'" \
export ndntest_vnf="$ndntest_vnf" \
'
  echo -e "\033[1mConnected $ndntest_vnf.\033[0m"

  vnf_aliases=($vnf_aliases)
  vnf_prefixes=($vnf_prefixes)
  vnf_mgmt_ips=($vnf_mgmt_ips)

  if [ ! -f ~/.ssh/id_rsa ]; then
    sed -i "s/nova\.clouds\.archive\.ubuntu\.com/ftp\.daumkakao\.com/g" /etc/apt/sources.list
    sed -i "s/security\.ubuntu\.com/ftp\.daumkakao\.com/g" /etc/apt/sources.list
    apt update -y
    apt install -y sshpass
    echo -e "\n\n\n" | ssh-keygen -t rsa
  fi

  for key in ${!vnf_mgmt_ips[@]}
  do
    if [[ "${vnf_aliases[$key]}" = "$ndntest_vnf" ]]; then
      break;
    fi
    echo ""
    echo ""
    echo -e "\033[1mName-based ping test from [$ndntest_vnf] to [${vnf_aliases[$key]}].\033[0m"
    vnf_prefix=(${vnf_prefixes[$key]//:/ })
    ping_prefix=${vnf_prefix[0]}
    ndnping -c 1 ndn:/ndn/${ping_prefix//\\/} | head -n 2
    sleep 2

    echo ""
    echo -e "\033[1mName-based subscriber test from [$ndntest_vnf] to [${vnf_aliases[$key]}].\033[0m"
    ndnpeek -p ndn:/ndn/${ping_prefix//\\/}
    sleep 2

    echo ""
    echo -e "\033[1mCheck Publisher FIB information in [${vnf_aliases[$key]}].\033[0m"
    sshpass -p 'root' ssh-copy-id -f -o StrictHostKeyChecking=no root@${vnf_mgmt_ips[$key]}
    tmp_prefix=${ping_prefix//\\/}

    ssh -o StrictHostKeyChecking=no root@${vnf_mgmt_ips[$key]} \
    vnf_prefix=$tmp_prefix \
"
nfdc fib list | grep $vnf_prefix
"
  done
'

fi

# transmit a single packet between a consumer and a producer
# ssh 192.168.100.150
# echo 'ContentData response from Seoul Center VNF' | ndnpoke ndn:/ndn/seoul/gwanak/police/client
# ssh 192.168.100.157
# ndnpeek -p ndn:/ndn/seoul/gwanak/police/client

# test reachability between two nodes
# ssh 192.168.100.150
# ndnpingserver -t ndn:/ndn/seoul/center 1> ndnpingserver.out 2>&1 &
# ssh 192.168.100.157
# ndnping -c 1 ndn:/ndn/seoul/center


# test ndn message chat between two nodes (nlsr is disabled)
# ssh 192.168.100.153
# python ~/PyNDN2/examples/test_chrono_chat.py
# 10.10.14.153
#
# ssh 192.168.100.157
# python ~/PyNDN2/examples/test_chrono_chat.py
# 10.10.14.153
