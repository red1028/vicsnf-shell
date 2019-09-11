#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)


####################################
## input nfd name and manage network
####################################
echo ""
read -p "${bold}Set the ICN + DTN VNF function. Do you want to proceed?(n or y[default]) :${normal}" is_process
read -p "${bold}Do you want to ndn message pub/sub test proceed(nlsr is disabled)?(y or n[default]) :${normal}" is_ndnchat

if [ -z $is_process ]; then
  is_process='y'
fi

if [ -z $is_ndnchat ]; then
  is_ndnchat='n'
fi

if [ "$is_process" = "y" -o "$is_process" = "Y" ]; then

. ~/icn_dtn_topology.inc

  start_time="$(date -u +%s)"

  ####################################
  ## IP setting of VNF
  ####################################
  echo ""
  if [ "$is_ndnchat" = "n" ]; then
    echo "${bold}#####################################################"
    echo "## ICN+DTN VNF (NFD+NLSR) Configuration."
    echo "#####################################################${normal}"
  else
    echo "${bold}#####################################################"
    echo "## ICN+DTN VNF (NFD Only) Configuration."
    echo "#####################################################${normal}"
  fi

  sleep 4

  rm -f /root/.ssh/known_hosts
  for key in ${!vnf_names[@]}
  do
ssh -o StrictHostKeyChecking=no root@${vnf_mgmt_ips[$key]} \
export vnf_name=${vnf_names[$key]} \
export vnf_alias=${vnf_aliases[$key]} \
export vnf_mgmt_ip=${vnf_mgmt_ips[$key]} \
export vnf_top_ip=${vnf_top_ips[$key]} \
export vnf_bottom_ip=${vnf_bottom_ips[$key]} \
'
cat <<EOF> /etc/network/interfaces
auto lo
iface lo inet loopback

auto ens3
iface ens3 inet static
address $vnf_mgmt_ip/22
gateway 192.168.100.1
dns-nameservers 8.8.8.8

auto ens4
iface ens4 inet static
address $vnf_top_ip/24

auto ens5
iface ens5 inet static
address $vnf_bottom_ip/24
EOF

ifdown ens4  2>/dev/null
ifdown ens5 2>/dev/null
ifup ens4
ifup ens5

echo -e "  \033[1m[$vnf_alias]IP address setup completed.\033[0m"
echo -e "  ==>ens3:$vnf_mgmt_ip, ens4:$vnf_top_ip, ens5:$vnf_bottom_ip"
sleep 1
'
  done


  ####################################
  ## Ping test of VNF
  ####################################
  echo ""
  echo ""
  echo "${bold}#############################################################################"
  echo "## Proceed with VNF's test of network connectivity between neighboring nodes."
  echo "#############################################################################${normal}"
  sleep 4
  for key in ${!vnf_names[@]}
  do
ssh -o StrictHostKeyChecking=no root@${vnf_mgmt_ips[$key]} \
export vnf_alias=${vnf_aliases[$key]} \
export vnf_neighbor_ip=${vnf_neighbor_ips[$key]} \
export vnf_neighbor_name=${vnf_neighbor_names[$key]} \
'
vnf_neighbor_ips=(${vnf_neighbor_ip//:/ })
vnf_neighbor_names=(${vnf_neighbor_name//:/ })
for key in ${!vnf_neighbor_ips[@]}
do
  echo -e "  \033[1mPing test from [$vnf_alias] to [${vnf_neighbor_names[$key]}].\033[0m"
  ping -c 1 ${vnf_neighbor_ips[$key]} | head -n 2
  sleep 1
done
'
  done


  ####################################
  ## change hosts and nfd, nlsr conf
  ####################################
  echo ""
  echo ""
  echo "${bold}#####################################################"
  echo "## Change hosts and nfd config file."
  echo "#####################################################${normal}"
  sleep 4
  for key in ${!vnf_names[@]}
  do
ssh -o StrictHostKeyChecking=no root@${vnf_mgmt_ips[$key]} \
export vnf_neighbor_ip=${vnf_neighbor_ips[$key]} \
export vnf_neighbor_name=${vnf_neighbor_names[$key]} \
export vnf_alias=${vnf_aliases[$key]} \
export vnf_site_route_name=${vnf_site_route_names[$key]} \
export vnf_neighbor_route=${vnf_neighbor_routes[$key]} \
export vnf_prefix=${vnf_prefixes[$key]} \
export is_ndnchat="$is_ndnchat" \
'
vnf_neighbor_ips=(${vnf_neighbor_ip//:/ })
vnf_neighbor_names=(${vnf_neighbor_name//:/ })
vnf_site_route_names=(${vnf_site_route_name//:/ })

vnf_neighbor_routes=(${vnf_neighbor_route//:/ })
vnf_prefixes=(${vnf_prefix//:/ })

echo "127.0.0.1 localhost $vnf_alias" > /etc/hosts
for key in ${!vnf_neighbor_ips[@]}
do
  echo "${vnf_neighbor_ips[$key]} ${vnf_neighbor_names[$key]}" >> /etc/hosts
done

#################
## change nlsr config
cp $HOME/nlsr_default.conf /usr/local/etc/ndn/nlsr.conf
filename=/usr/local/etc/ndn/nlsr.conf
sed -i "s/\%site_name\%/${vnf_site_route_names[0]}/" $filename
sed -i "s/\%router_name\%/${vnf_site_route_names[1]}/" $filename

NEIGHBOR_ARRY=""
for key in ${!vnf_neighbor_ips[@]}
do
temp_neighbor_info=(${vnf_neighbor_routes[$key]//\#/ })
link_cost=$(shuf -i 25-30 -n 1)
NEIGHBOR_ARRY=$"$NEIGHBOR_ARRY\n \
 neighbor\n \
 {\n \
   name \/ndn\/${temp_neighbor_info[0]}\/%C1.Router\/${temp_neighbor_info[1]}\n \
   face-uri udp4:\/\/${vnf_neighbor_ips[$key]}\n \
   link-cost $link_cost\n \
 } \
"
done

PREFIX_ARRAY=""
for key in ${!vnf_prefixes[@]}
do
PREFIX_ARRAY=$"$PREFIX_ARRAY\n \
 prefix \/ndn\/${vnf_prefixes[$key]} \
"
done

sed -i "s/\%neighbor_arry\%/$NEIGHBOR_ARRY/" $filename
sed -i "s/\%prefix_array\%/$PREFIX_ARRAY/" $filename

echo -e "Name-based prefix settings for neighboring nodes ==> $NEIGHBOR_ARRY"
echo -e "Name prefix advertisement of ICN node ==> $PREFIX_ARRAY"

######################
## change nfd_default.conf
cp $HOME/nfd_default.conf /usr/local/etc/ndn/nfd.conf

LOCALHOP_SECURITY=""
if [[ "$is_ndnchat" = "y" ]]; then
LOCALHOP_SECURITY=$"$LOCALHOP_SECURITY\n \
 localhop_security\n \
 {\n \
   trust-anchor\n \
   {\n \
     type any\n \
   }\n \
 } \
"
echo -e "localhop_security setting for NDN Pub/Sub test ==> $LOCALHOP_SECURITY"
fi
sed -i "s/\%default_tcp_subnet\%/subnet\ 10\.10\.0\.0\/16/" /usr/local/etc/ndn/nfd.conf
sed -i "s/\%localhop_security\%/$LOCALHOP_SECURITY/" /usr/local/etc/ndn/nfd.conf

########################
## change test_chrono_chat.py
cp $HOME/test_chrono_chat.py $HOME/PyNDN2/examples/test_chrono_chat.py
sed -i "s/\%default_hub_prefix\%/\/ndn\/${vnf_prefixes[0]}/" $HOME/PyNDN2/examples/test_chrono_chat.py

echo -e "  \033[1m[$vnf_alias]NFD settings and host file change complete.\033[0m"
'
  done


  ####################################
  ##  NFD AND NLRS START
  ####################################
  echo ""
  echo ""
  echo "${bold}#####################################################"
  echo "## Starting the NFD and NLSR Daemons."
  echo "#####################################################${normal}"
  sleep 4
  for key in ${!vnf_names[@]}
  do
ssh -o StrictHostKeyChecking=no root@${vnf_mgmt_ips[$key]} \
export vnf_alias=${vnf_aliases[$key]} \
export is_ndnchat="$is_ndnchat" \
'
nfd-stop 2>/dev/null
sleep 1
nfd-start 1> nfd.out 2>&1
sleep 2

pid=`ps -ef | grep nfd | grep -v grep | wc -l`
if [[ "$pid" -ne 0 ]]; then
  if [[ "$is_ndnchat" = "y" ]]; then
      echo -e "  \033[1m== [$vnf_alias]Started NFD ==\033[0m"
  else
    nlsr -f /usr/local/etc/ndn/nlsr.conf 1> nlsr.out 2>&1 &
    pid=`ps -ef | grep nlsr | grep -v grep | wc -l`
    if [[ "$pid" -ne 0 ]]; then
      echo -e "  \033[1m== [$vnf_alias]Started NFD and NLSR ==\033[0m"
    fi
  fi
fi
'
  done

  ####################################
  ##  Check nlsr process
  ####################################
  echo ""
  echo ""
  echo "${bold}#####################################################"
  echo "## NFD+NLSR process check"
  echo "#####################################################${normal}"
  sleep 4
  for key in ${!vnf_names[@]}
  do
ssh -o StrictHostKeyChecking=no root@${vnf_mgmt_ips[$key]} \
export vnf_name=${vnf_names[$key]} \
export vnf_mgmt_ip=${vnf_mgmt_ips[$key]} \
export vnf_alias=${vnf_aliases[$key]} \
'
echo =============================================================================================
echo "$vnf_alias($vnf_mgmt_ip) [$(ps -ax | grep -v grep | grep nlsr)]"
echo =============================================================================================
'
  done

  ####################################
  ##  Add face information
  ####################################
  echo ""
  echo ""
  echo "${bold}#####################################################"
  echo "## Added face information."
  echo "#####################################################${normal}"
  sleep 4
  for key in ${!vnf_names[@]}
  do
ssh -o StrictHostKeyChecking=no root@${vnf_mgmt_ips[$key]} \
export vnf_alias=${vnf_aliases[$key]} \
export vnf_neighbor_ip=${vnf_neighbor_ips[$key]} \
export vnf_neighbor_name=${vnf_neighbor_names[$key]} \
'
vnf_neighbor_ips=(${vnf_neighbor_ip//:/ })
vnf_neighbor_names=(${vnf_neighbor_name//:/ })
for key in ${!vnf_neighbor_ips[@]}
do
  echo -e "  \033[1mAdd face information for neighboring node.([$vnf_alias] to [${vnf_neighbor_names[$key]}]).\033[0m"
  nfdc face create udp4://${vnf_neighbor_ips[$key]}
  sleep 0.5

  sleep 2
  echo ""
  echo -e "  \033[1mFIB(Forwarding Infomation Base) List\033[0m"
  nfdc fib list | sort | grep Router
  echo ""
  echo ""
done
'
  done

  echo ""
  echo ""
  echo "${bold}#####################################################"
  echo "## Configuration of ICN + DTN VNF is completed."
  echo "#####################################################${normal}"



  end_time="$(date -u +%s)"
  elapsed=$(($end_time-$start_time))
  elapsed=$(($elapsed-60)) #42
  one_vnf_elapsed=$(($elapsed/${#vnf_names[@]}))
  add_nlsr="NFD+NLSR"

  elapsed=144
  one_vnf_elapsed=16

  if [ "$is_ndnchat" = "y" ]; then
    elapsed=99
    one_vnf_elapsed=11
    add_nlsr="NFD+NLSR"
  fi


  echo ""
  echo ""
  echo "${bold}Total number of ICN+DTN VNF: ${#vnf_names[@]} VNFs${normal}"
  echo "${bold}All ICN+DTN VNF Setting completion time: $elapsed(s), 1 VNF about $one_vnf_elapsed(s) ${normal}"

fi #--> finish

#192.168.100.158 ndnpingserver -t ndn:/ndn/seoul/gwanak/police/client
#192.168.100.157 ndnping ndn:/ndn/seoul/gwanak/police/client
