#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

# sample ENVIRONMENT VALUE
##export vICSNF_ALIAS='b247f7840139'
##export vICSNF_MGMTIP='192.168.103.250'
##export vICSNF_MGMTPORT='50051'
##export vICSNF_SITENAME='seoul\\/donjak'
##export vICSNF_ROUTERNAME='center'
##export vICSNF_NEIGHBOR_HOSTNAME='donjak:gwanak'
##export vICSNF_NEIGHBOR_IP='10.10.11.151:10.10.11.152'
##export vICSNF_NEIGHBOR_SITE_ROUTE='seoul\\/donjak#center:seoul\\/gwanak#center'
##export vICSNF_AD_PREFIXE='seoul\\/center:seoul\\/gwanak#center'
##export vICSNF_ENV_CHANGE='NO'
##export vICSNF_IS_START='NO'
##export vDTN_SUPPORT='YES'
##export vCONVERGENCE_INTERFACES='lan0:lan1'
##export vCONVERGENCE_LAYER='tcp#eth0:tcp#eth1'
##export vDTN_DEFAULT_PREFIX='\\/nfd\\/dtn'

function env_to_file()
{
  echo "FILENAME=/root/$1" > /root/$1
  echo "MGMTIP=$vICSNF_MGMTIP" >> /root/$1
  echo "MGMTPORT=$vICSNF_MGMTPORT" >> /root/$1
  echo "ALIAS=$vICSNF_ALIAS" >> /root/$1
  echo "SITENAME=$vICSNF_SITENAME" >> /root/$1
  echo "ROUTERNAME=$vICSNF_ROUTERNAME" >> /root/$1
  echo "NEIGHBOR_HOSTNAME=$vICSNF_NEIGHBOR_HOSTNAME" >> /root/$1
  echo "NEIGHBOR_IP=$vICSNF_NEIGHBOR_IP" >> /root/$1
  echo "NEIGHBOR_SITE_ROUTE=$vICSNF_NEIGHBOR_SITE_ROUTE" >> /root/$1
  echo "AD_PREFIXE=$vICSNF_AD_PREFIXE" >> /root/$1
  echo "ENV_CHANGE=$vICSNF_ENV_CHANGE" >> /root/$1
  ## dtn case
  echo "DTN_SUPPORT=$vDTN_SUPPORT" >> /root/$1
  echo "CONVERGENCE_INTERFACES=$vCONVERGENCE_INTERFACES" >> /root/$1
  echo "CONVERGENCE_LAYER=$vCONVERGENCE_LAYER" >> /root/$1
  echo "DTN_DEFAULT_PREFIX=$vDTN_DEFAULT_PREFIX" >> /root/$1

  if [ -z "$vICSNF_IS_START" ]; then
     env vICSNF_IS_START='YES' 
  fi
  echo "IS_START=$vICSNF_IS_START" >> /root/$1

  if [ -z "$vNLSR_LIFETIME" ]; then
     env vNLSR_LIFETIME='60000' 
  fi
  echo "NLSR_LIFETIME=$vNLSR_LIFETIME" >> /root/$1

  echo "IS_VM=$vICSNF_IS_VM" >> /root/$1
}

function apply_to_ndn()
{
. /root/$1

LOCAL_ETC_PATH='/usr/local/etc'
cp $LOCAL_ETC_PATH/ndn/nlsr_default.conf $LOCAL_ETC_PATH/ndn/nlsr_$ALIAS.conf
filename=$LOCAL_ETC_PATH/ndn/nlsr_$ALIAS.conf

## neighbor and prefix
vnf_neighbor_ips=(${NEIGHBOR_IP//:/ })
vnf_neighbor_hostnames=(${NEIGHBOR_HOSTNAME//:/ })
vnf_neighbor_site_routes=(${NEIGHBOR_SITE_ROUTE//:/ })
vnf_advertising_prefixes=(${AD_PREFIXE//:/ })

#echo "${bold}#####################################################"
#echo "## Change hosts"
#echo "#####################################################${normal}"
test -f /etc/hosts.org || cp /etc/hosts /etc/hosts.org
if [ "$IS_VM" == "YES" ]; then
  echo "$(ip route get 8.8.8.8 | awk '{print $NF; exit}') $(hostname)" > /etc/hosts
else
  echo "$(hostname -i) $(hostname)" > /etc/hosts
fi

for key in ${!vnf_neighbor_ips[@]}
do
  echo "${vnf_neighbor_ips[$key]} ${vnf_neighbor_hostnames[$key]}" >> /etc/hosts
done
echo "127.0.0.1 localhost" >> /etc/hosts

#echo "${bold}#####################################################"
#echo "## Change nlsr.conf"
#echo "#####################################################${normal}"
## nlsr site and route name
sed -i "s/\%site_name\%/$SITENAME/" $filename
sed -i "s/\%router_name\%/$ROUTERNAME/" $filename

NEIGHBOR_ARRY=""
for key in ${!vnf_neighbor_ips[@]}
do
temp_neighbor_info=(${vnf_neighbor_site_routes[$key]//\#/ })

if [ "${temp_neighbor_info[0]}" != "not" ]; then
link_cost=$(shuf -i 25-30 -n 1)
NEIGHBOR_ARRY=$"$NEIGHBOR_ARRY\n \
 neighbor\n \
 {\n \
   name \/ndn\/${temp_neighbor_info[0]}\/%C1.Router\/${temp_neighbor_info[1]}\n \
   face-uri udp4:\/\/${vnf_neighbor_ips[$key]}\n \
   link-cost $link_cost\n \
 } \
"
fi

done

PREFIX_ARRAY=""
for key in ${!vnf_advertising_prefixes[@]}
do
PREFIX_ARRAY=$"$PREFIX_ARRAY\n \
 prefix \/ndn\/${vnf_advertising_prefixes[$key]} \
"
done

sed -i "s/\%neighbor_arry\%/$NEIGHBOR_ARRY/" $filename
sed -i "s/\%prefix_array\%/$PREFIX_ARRAY/" $filename
sed -i "s/60000/$NLSR_LIFETIME/" $filename

cp $filename $LOCAL_ETC_PATH/ndn/nlsr.conf


DTN_CONF=""
if [ $DTN_SUPPORT == 'YES' ]; then
DTN_CONF="dtn\n\
  {\n\
    host localhost\n\
    port 4550\n\
    endpointPrefix dtn:\/\/$ALIAS\n\
    endpointAffix $DTN_DEFAULT_PREFIX\n\
  }\
"
fi

cp $LOCAL_ETC_PATH/ndn/nfd_default.conf $LOCAL_ETC_PATH/ndn/nfd_$ALIAS.conf
filename=$LOCAL_ETC_PATH/ndn/nfd_$ALIAS.conf

sed -i "s/\%dtn_conf\%/$DTN_CONF/" $filename
cp $filename $LOCAL_ETC_PATH/ndn/nfd.conf
} # apply_to_ndn


function apply_to_dtn()
{
. /root/$1

LOCAL_ETC_PATH='/usr/local/etc'
cp $LOCAL_ETC_PATH/ibrdtnd_default.conf $LOCAL_ETC_PATH/ibrdtnd_$ALIAS.conf
filename=$LOCAL_ETC_PATH/ibrdtnd_$ALIAS.conf

## neighbor and prefix
convergence_interfaces=(${CONVERGENCE_INTERFACES//:/ })
convergence_layer=(${CONVERGENCE_LAYER//:/ })

#echo "${bold}#####################################################"
#echo "## Change ibrdtnd.conf"
#echo "#####################################################${normal}"
sed -i "s/\%hostname\%/$ALIAS/" $filename
sed -i "s/\%convergence_interfaces\%/${convergence_interfaces[*]// /}/" $filename

CONVERGENCE_LAYER_ARRAY=""
for key in ${!convergence_layer[@]}
do
temp_convergence_layer=(${convergence_layer[$key]//\#/ })

CONVERGENCE_LAYER_ARRAY=$"$CONVERGENCE_LAYER_ARRAY\n\
net_${convergence_interfaces[$key]}_type = ${temp_convergence_layer[0]}\n\
net_${convergence_interfaces[$key]}_interface = ${temp_convergence_layer[1]}\
"
done

sed -i "s/\%convergence_layer\%/$CONVERGENCE_LAYER_ARRAY/" $filename

cp $filename $LOCAL_ETC_PATH/ibrdtnd.conf
} # apply_to_dtn


function add_udp_face()
{
. /root/$1

vnf_neighbor_ips=(${NEIGHBOR_IP//:/ })
vnf_neighbor_hostnames=(${NEIGHBOR_HOSTNAME//:/ })
for key in ${!vnf_neighbor_ips[@]}
do
  #echo -e "  \033[1mAdd face information for neighboring node.([$ALIAS] to [${vnf_neighbor_hostnames[$key]}]).\033[0m"
  nfdc face create remote udp4://${vnf_neighbor_ips[$key]} persistency permanent
  sleep 1
  #sleep 2
  #echo ""
  #echo -e "  \033[1mFIB(Forwarding Infomation Base) List\033[0m"
  #nfdc fib list | sort | grep Router
  #echo ""
done
}

function add_tcp_face()
{
. /root/$1

vnf_neighbor_ips=(${NEIGHBOR_IP//:/ })
vnf_neighbor_hostnames=(${NEIGHBOR_HOSTNAME//:/ })
for key in ${!vnf_neighbor_ips[@]}
do
  nfdc face create remote tcp4://${vnf_neighbor_ips[$key]} persistency permanent
  sleep 1
done
}


function start_nfd()
{
  /root/service_nfd.sh start
}
function stop_nfd()
{
  /root/service_nfd.sh stop
}

function start_nlsr()
{
  /root/service_nlsr.sh start
}
function stop_nlsr()
{
  /root/service_nlsr.sh stop
}

function start_grpc_agent()
{
  /root/service_grpc.sh start
}
function stop_grpc_agent()
{
  /root/service_grpc.sh stop
}

function start_dtnd()
{
  /root/service_dtnd.sh start
}
function stop_dtnd()
{
  /root/service_dtnd.sh stop
}


env_name=''

if [[ $ENV_CHANGE == 'YES' ]]; then
  env_name='env_change'
  env_to_file $env_name
elif [[ -e '/root/env_next' ]]; then
  env_name='env_next'
elif [[ -e '/root/env_original' ]]; then
  env_name='env_original'
else
  env_name='env_original'
  env_to_file $env_name
fi

source $env_name

if [ "$1" == 'add_tcp' ]; then
  add_tcp_face $env_name
else
  # default command
  apply_to_ndn $env_name
  stop_dtnd; stop_nlsr; stop_nfd; stop_grpc_agent
 
  if [ $DTN_SUPPORT  == 'YES' ]; then
	apply_to_dtn $env_name
	start_dtnd;
  fi

  start_nfd
  if [ $IS_START == 'YES' ]; then
      start_nlsr; start_grpc_agent
  fi
  add_udp_face $env_name
fi
