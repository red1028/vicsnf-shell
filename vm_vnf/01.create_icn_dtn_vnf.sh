#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

####################################
## input nfd name and manage network
####################################
read -p "${bold}Enter the base name of icn+dtn image(icn_dtn_base[default]) :${normal}" image_name
read -p "${bold}Enter the version of icn+dtn (0.6.5[default]) :${normal}" version
read -p "${bold}Enter the management network for creating an icn+dtn image(public[default]) :${normal}" mgmt_net
read -p "${bold}Are you sure you want to delete it?(y or n[default]) :${normal}" is_delete
read -p "${bold}Support Web-VNC in VM?(y or n[default]) :${normal}" is_vnc


if [[ -z $image_name ]]; then
  image_name='icn_dtn_base'
fi
if [[ -z $version ]]; then
  version='0.6.5'
fi
if [[ -z $mgmt_net ]]; then
  mgmt_net='public'
fi
if [[ -z $is_delete ]]; then
  is_delete='n'
fi
if [[ -z $is_vnc ]]; then
  is_vnc='n'
fi


####################################
## install nfd+nlsr
####################################
function nfd_nlsr_install()
{
ssh -o StrictHostKeyChecking=no root@$1 \
'
echo ""
echo -e "\033[1mConnected to VM\033[0m"
echo -e "\033[1mInstallation ICN+DTN libraries\033[0m"

echo "" >> /etc/vim/vimrc
echo "colorscheme ron"  >> /etc/vim/vimrc
echo "LS_COLORS=\$LS_COLORS:\"di=1;33:ln=36\"; export LS_COLORS" >> ~/.bashrc

#############
# change repository
sed -i "s/nova\.clouds\.archive\.ubuntu\.com/ftp\.daumkakao\.com/g" /etc/apt/sources.list
sed -i "s/security\.ubuntu\.com/ftp\.daumkakao\.com/g" /etc/apt/sources.list
apt update

#############
# Installing Packages for ndn-cxx and nfd Builds
apt install -y devscripts build-essential libtool cdbs pkg-config debhelper autotools-dev \
 libnl-3-dev libnl-genl-3-dev libnl-route-3-dev libnl-nf-3-dev libnl-cli-3-dev libssl-dev \
 zlib1g-dev libsqlite3-dev libcurl4-openssl-dev libdaemon-dev libvmime-dev libarchive-dev \
 psmisc libpcap-dev libboost-all-dev python-pip curl git libffi-dev \
 automake autoconf libcppunit-dev libcrypto++-dev liblog4cxx-dev libprotobuf-dev protobuf-compiler libsystemd-dev

sysctl -w net.ipv6.conf.all.disable_ipv6=1

#############
# Installing pip package for ndn-grpc
python -m pip install --upgrade pip
python -m pip install futures
python -m pip install grpcio
python -m pip install protobuf
python -m pip install netifaces
python -m pip install ifaddr

mkdir ~/logs
mkdir ~/ndn_dtn_source

#############
## download nlsr (ykpark version)
cd ~/ndn_dtn_source
git clone https://github.com/red1028/ibrdtn.git
git clone https://github.com/red1028/ndn-cxx-0.6.5
git clone https://github.com/red1028/NFD-0.6.5
git clone https://github.com/red1028/ndn-cxx-0.6.6
git clone https://github.com/red1028/NFD-0.6.6

git clone -b 0.5.2 https://github.com/named-data/ChronoSync.git
git clone -b 0.1.0 https://github.com/named-data/PSync.git
git clone https://github.com/red1028/vicsnf-shell.git

## case of nfd v0.6.5
git clone -b ndn-tools-0.6.3 https://github.com/named-data/ndn-tools.git ndn-tools-0.6.3
git clone -b NLSR-0.5.0 https://github.com/named-data/NLSR.git NLSR-0.5.0
git clone -b v2.10beta1 https://github.com/named-data/PyNDN2.git PyNDN2-0.6.5

## case of nfd v0.6.6
git clone -b ndn-tools-0.6.4 https://github.com/named-data/ndn-tools.git ndn-tools-0.6.4
git clone -b NLSR-0.5.1 https://github.com/named-data/NLSR.git NLSR-0.5.1
curl -L -o PyNDN2-0.6.6.zip "https://drive.google.com/uc?export=download&id=1zl9UH3C7aKDJpbcxZcaaKYGjHMIgQ0Pc"
unzip PyNDN2-0.6.6.zip
mv PyNDN2-2.10beta1 PyNDN2-0.6.6
cd PyNDN2-0.6.6
chmod a+x configure

#############
# 01. ibrdtn compile
# extract source file
cd ~/ndn_dtn_source/ibrdtn/
bash ./ibrdtn-1.0.1.sh

#############
# build ibr-dtn
cd ~/ndn_dtn_source/ibrdtn/ibrcommon-1.0.1
./configure --with-openssl
make && make install
ln -s /usr/local/lib/libibrcommon-1.0.so.1.0.0 /usr/lib/libibrcommon.so
ldconfig

cd ~/ndn_dtn_source/ibrdtn/ibrdtn-1.0.1
./configure
make && make install
ln -s /usr/local/lib/libibrdtn-1.0.so.1.0.0 /usr/lib/libibrdtn.so
ldconfig

cd ~/ndn_dtn_source/ibrdtn/ibrdtnd-1.0.1
./configure --with-curl
make && make install
ldconfig

cd ~/ndn_dtn_source/ibrdtn/ibrdtn-tools-1.0.1
./configure
make && make install
ldconfig

#############
# build ndn
cd ~/ndn_dtn_source/ndn-cxx-$version
./waf clean && ./waf configure --with-examples
./waf && ./waf install
cp build/examples/{consumer,producer,consumer-with-timer} /usr/local/bin
ldconfig

cd ~/ndn_dtn_source/NFD-$version
mkdir -p websocketpp
if [ "$version" == "0.6.5" ]; then
  curl -L https://github.com/zaphoyd/websocketpp/archive/0.8.1.tar.gz > websocketpp.tar.gz
else
  curl -L https://github.com/cawka/websocketpp/archive/0.8.1-hotfix.tar.gz > websocketpp.tar.gz
fi
tar xf websocketpp.tar.gz -C websocketpp/ --strip 1
./waf clean && ./waf configure
./waf && ./waf install
sed -i "s/^sudo //" /usr/local/bin/nfd-start
sed -i "s/\! sudo true/[ \"1\" == \"0\" ]/" /usr/local/bin/nfd-start
sed -i "s/sudo killall nfd/killall -9 nfd/" /usr/local/bin/nfd-stop

## ChronoSync build
cd ~/ndn_dtn_source/ChronoSync
./waf clean && ./waf configure
./waf && ./waf install
ldconfig

cd ~/ndn_dtn_source/PSync
./waf clean && ./waf configure
./waf && ./waf install
ldconfig

## NLSR build
mkdir -p /var/lib/nlsr
if [ "$version" == "0.6.5" ]; then
  cd ~/ndn_dtn_source/NLSR-0.5.0
else
  cd ~/ndn_dtn_source/NLSR-0.5.1
fi
./waf clean && ./waf configure
./waf && ./waf install

#############
# build ndn-tools
if [ "$version" == "0.6.5" ]; then
  cd ~/ndn_dtn_source/ndn-tools-0.6.3
else
  cd ~/ndn_dtn_source/ndn-tools-0.6.4
fi
./waf clean && ./waf configure
./waf && ./waf install

#############
# build PyNDN2
cd ~/ndn_dtn_source/PyNDN2-$version
./configure
make && make install
python setup.py install

#############
# Copy the start shell file and default configure file
cd ~/ndn_dtn_source/vicsnf-shell
cp *.sh ~/
cp ibrdtnd_default.conf /usr/local/etc
cp {nfd_default,nlsr_default}.conf /usr/local/etc/ndn
#cp /usr/local/etc/ndn/autoconfig.conf.sample /usr/local/etc/ndn/autoconfig.conf
#sed -i "s/false/true/g" /usr/local/etc/ndn/autoconfig.conf

#############
# nfd command for grpc
git clone https://github.com/red1028/nfd-grpc.git  ~/nfd-grpc


############
# pyndn client for icn+dtn
############
if [ "$is_vnc" == "y" ]; then
  apt-get install -y software-properties-common
  add-apt-repository ppa:kivy-team/kivy
  apt-get install -y python-kivy
  apt-get install -y libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-mixer-2.0-0 libsdl2-ttf-2.0-0
  easy_install requests
  git clone https://github.com/pearltran/py_chronochat_ui.git ~/py_chronochat_ui
fi
'
}



####################################
## check nfd snapshot image
####################################
is_nfd_image=$(openstack image list | grep $image_name_$version | awk '/ / {print $4}')

if [[ -n $is_nfd_image ]]; then
  read -p "${bold}Already exists ICN+DTN image ($is_nfd_image). Are you sure you want to proceed(y or n[default])? :${normal}" yesorno
  if [[ -z $yesorno ]]; then
    yesorno='n'
  fi
else
  yesorno='y'
fi

####################################
## delete and proceed?
####################################
if [ "$yesorno" = "y" -o "$yesorno" = "Y" ]; then
  uuid=$(uuidgen)
  uuid=${uuid:0:13}
  uuid=${uuid^^}
  #name=$name\_$uuid
  name=$image_name\_$version

  ####################################
  ## Create empty VNF
  ####################################
  echo ""
  echo "${bold}Create default ICN+DTN VNF ($name)${normal}"
  openstack server delete $name
  sleep 4
  openstack server create \
   --image xenial-server \
   --flavor ds2G \
   --network $mgmt_net \
   --availability-zone nova:vicsnet-core1 \
  $name

  ####################################
  ## Check VNF status
  ####################################
  echo ""
  start_time="$(date -u +%s)"
  for (( ; ; ))
  do
    #is_active=$(openstack server list | grep $name | awk '/ ACTIVE / {print $6}')
    is_active=$(openstack server list | grep $name | awk '/ / {print $6}')
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

  ####################################
  ## Connect VNF and NFD install process 
  ####################################
  echo ""
  echo "${bold}Connection for ICN+DTN installation${normal}"
  mgmt_ip=$(openstack server list | grep $name | awk -F"public=" '{print $2}' | awk '{print $1}')
  for (( ; ; ))
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
  ## copy ssh-keygen 
  ####################################
  apt install -y sshpass
  if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen
  fi
  sshpass -p 'root' ssh-copy-id -f -o StrictHostKeyChecking=no root@$mgmt_ip;

  ####################################
  ## ssh connect and nfd install
  ####################################
  nfd_nlsr_install $mgmt_ip

  ####################################
  ## Reboot VNF status
  ####################################
  echo ""
  echo "${bold}ICN+DTN library installation completed and VNF rebooting...${normal}"
  prev_status=""
  openstack server reboot $name
  for (( ; ; ))
  do
    is_active=$(openstack server list | grep $name | awk '/ / {print $6}')
    if [[ "$is_active" = "ACTIVE" ]]; then 
      break
    fi
    if [[  $is_active != "$prev_status" ]]; then
      prev_status="$is_active"
      echo "VNF reboot status $is_active"	
    fi
  done
  echo "${bold}VNF reboot completed ($is_active)${normal}"

  ####################################
  ## Check create snapshot status
  ####################################
  echo ""
  echo "${bold}Create default ICN+DTN VNF image ($name)${normal}"
  prev_status=""
  openstack server image create $name --name $name
  for (( ; ; ))
  do
    is_active=$(openstack image list | grep $name | awk '/ / {print $6}')
    if [[ "$is_active" = "active" ]]; then 
      break
    fi
    if [[ $is_active != "$prev_status" ]]; then
      prev_status="$is_active"
      echo "Create VNF image status $is_active"	
    fi
  done
  echo "${bold}Create VNF image completed ($is_active)${normal}"

  ####################################
  ## Check create snapshot status
  ####################################
  if [ "$is_delete" = "y" ]; then
    openstack server delete $name
  fi
fi
