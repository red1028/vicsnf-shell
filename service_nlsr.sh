#!/bin/bash

function start()
{
  pid=`ps -aef | grep 'bin/nfd' | grep -v grep | wc -l`
  if [[ $pid -eq 0 ]]; then
    /root/service_nfd.sh start
  fi

  nlsr -f /usr/local/etc/ndn/nlsr.conf 1> /root/logs/nlsr.out 2>&1 &
  pid=`ps -ef | grep nlsr | grep -v grep | wc -l`
  if [[ $pid -ne 0 ]]; then
    sleep 2
    echo -e "\033[1m== Started NLSR ==\033[0m"
  fi
}
function stop()
{
  pid=`ps -ef | grep -n 'nlsr -f' | grep -v grep | awk '{ print $2 }'`
  if [[ $pid ]]; then
    kill -9 $pid 2>/dev/null
    #or pkill -f nlsr 2>/dev/null
    sleep 1
    echo -e "\033[1m== Stoped NLSR ==\033[0m"
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
