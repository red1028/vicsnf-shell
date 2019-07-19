#!/bin/bash

function start()
{
  pid=`ps -aef | grep nfd_agent | grep -v grep | wc -l`
  if [[ $pid -eq 0 ]]; then
	#/root/nfd_grpc/dist/nfd_agent 1> /root/nfd_agent.out 2>&1 &
	python /root/nfd_grpc/nfd_agent.py 2>&1 &
	sleep 2
    echo -e "\033[1m== Started nfd_agent ==\033[0m"
  else
    echo -e "\033[1m== Already started nfd_agent ==\033[0m"
  fi
}
function stop()
{
  pid=`ps -ef | grep nfd_agent | grep -v grep | awk '{ print $2 }'`
  if [[ $pid ]]; then
    #or kill -9 $pid 2>/dev/null
    pkill -f nfd_agent 2>/dev/null
    sleep 1
    echo -e "\033[1m== Stoped nfd_agent ==\033[0m"
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
