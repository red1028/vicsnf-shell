#!/bin/bash

function start()
{
  nfd-start 1> /root/logs/nfd.out 2>&1
  sleep 2
  echo -e "\033[1m== Started NFD ==\033[0m"
}
function stop()
{
  /root/service_nlsr.sh stop
  nfd-stop 2>/dev/null
  sleep 1
  echo -e "\033[1m== Stoped NFD ==\033[0m"
}

if [[ $1 == 'start' ]]; then
  start
elif [[ $1 == 'stop' ]]; then
  stop
elif [[ $1 == 'restart' ]]; then
  stop
  start
else
  echo 'Unrecognized option $1'
fi
