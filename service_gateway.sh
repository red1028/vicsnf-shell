#!/bin/bash

function start()
{
  pid=`ps -aef | grep gatewayRouter | grep -v grep | wc -l`
  if [[ $pid -eq 0 ]]; then
	python /root/wifi-kivyndnchat/gatewayRouter.py 2>&1 &
	sleep 2
    echo -e "\033[1m== Started gatewayRouter ==\033[0m"
  else
    echo -e "\033[1m== Already gatewayRouter ==\033[0m"
  fi
}
function stop()
{
  pid=`ps -ef | grep gatewayRouter | grep -v grep | awk '{ print $2 }'`
  if [[ $pid ]]; then
    pkill -f gatewayRouter 2>/dev/null
    sleep 1
    echo -e "\033[1m== Stoped gatewayRouter ==\033[0m"
  fi
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
