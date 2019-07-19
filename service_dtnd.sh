#!/bin/bash

function start()
{
  dtnd -c /usr/local/etc/ibrdtnd.conf 1> /root/logs/dtnd.out 2>&1 &
  pid=`ps -ef | grep dtnd | grep -v grep | wc -l`
  if [[ $pid -ne 0 ]]; then
    sleep 2
    echo -e "\033[1m== Started DTND ==\033[0m"
  fi
}
function stop()
{
  pid=`ps -ef | grep -n 'dtnd -c' | grep -v grep | awk '{ print $2 }'`
  if [[ $pid ]]; then
    kill -9 $pid 2>/dev/null
    #or pkill -f dtnd 2>/dev/null
    sleep 1
    echo -e "\033[1m== Stoped DTND ==\033[0m"
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
