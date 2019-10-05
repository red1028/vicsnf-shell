#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

####################################
## input container name and version...
####################################
read -p "${bold}Enter the base name of icn-dtn image(icn-dtn-base[default]) :${normal}" image_name
read -p "${bold}Enter the version of icn-dtn (0.6.5[default]) :${normal}" ndn_version
read -p "${bold}Enter the tag version of icn-dtn image (0.9[default]) :${normal}" tag_version
read -p "${bold}Support Web-VNC in continer?(y or n[default]) :${normal}" is_vnc

if [[ -z $ndn_version ]]; then
  ndn_version='0.6.5'
fi
if [[ -z $tag_version ]]; then
  tag_version='0.9'
fi
if [[ -z $image_name ]]; then
  image_name='icn-dtn-base'
fi
if [[ -z $is_vnc ]]; then
  is_vnc='n'
fi

####################################
## create default container image 
####################################
echo "${bold}Create icn-dtn container image ($image_name-$ndn_version:$tag_version)${normal}"
echo "${bold}Deleate container image${normal}"
docker rmi -f $image_name-$ndn_version:$tag_version
#docker rmi -f 192.168.103.250:5000/$image_name-$ndn_version:$tag_version

echo "${bold}Create container image${normal}"
docker build --tag $image_name-$ndn_version:$tag_version -f Dockerfile_icn_dtn .
#docker build --tag 192.168.103.250:5000/$image_name-$ndn_version:$tag_version -f Dockerfile_icn_dtn .
docker images | grep $image_name-vnc
#docker push 192.168.103.250:5000/$image_name-$ndn_version:$tag_version


####################################
## create default container image for web-vnc
####################################
if [[ $is_vnc == 'y' ]]; then

echo "${bold}Create icn-dtn container image for web-vnc ($image_name-vnc-$ndn_version:$tag_version)${normal}"

############
# create vnc
############
pushd /tmp
git clone https://github.com/ConSol/docker-headless-vnc-container
cd /tmp/docker-headless-vnc-container
sed -i 's/ubuntu:16.04/$image_name-$ndn_version:$tag_version/g' Dockerfile.ubuntu.xfce.vnc
echo "echo '[ \"\$(id -u)\" == \"0\" ] && source /root/.bashrc' >> \$HOME/.bashrc" >> ./src/ubuntu/install/libnss_wrapper.sh

cd /tmp/docker-headless-vnc-container/src/common/xfce/.config
wget -Nc https://xubuntu.org/wp-content/uploads/2018/07/6e3e/xubuntu-xenial.png
sed -i 's/bg_sakuli.png/xubuntu-xenial.png/g' xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

cd /tmp/docker-headless-vnc-container
echo "${bold}Deleate container image${normal}"
docker rmi -f $image_name-vnc-$ndn_version:$tag_version
#docker rmi -f 192.168.103.250:5000/$image_name-vnc-$ndn_version:$tag_version

echo "${bold}Create container image${normal}"
docker build --tag $image_name-vnc-$ndn_version:$tag_version -f Dockerfile.ubuntu.xfce.vnc .
#docker build -t 192.168.103.250:5000/$image_name-vnc-$ndn_version:$tag_version -f Dockerfile.ubuntu.xfce.vnc .
docker images | grep $image_name-vnc
#docker push 192.168.103.250:5000/$image_name-vnc-$ndn_version:$tag_version

popd
fi
