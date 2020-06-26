#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

####################################
## input nfd name and manage network
####################################
read -p "${bold}ICN+DTN distribute c-vnf to the system. Do you want to proceed?(n or y[default]) :${normal}" is_process

if [ -z $is_process ]; then
  is_process='y'
fi

if [ "$is_process" = "y" -o "$is_process" = "Y" ]; then

  pushd ./pod/vicsnf
  file_array=($(ls *.yaml | cut -d "." -f -1))
  
  echo "${bold}List of current CVNF Descriptions."
  echo "Please select Description of C-VNF to create."
  echo "The entire creation is 'all'.${normal}"
  
  vnf_list_str=""
  for key in ${!file_array[@]}
  do
    vnf_list_str="$vnf_list_str [${file_array[$key]}]"
  done
  echo ${bold}$vnf_list_str${normal}
  
  echo 
  read -p "${bold}Please select Description of C-VNF?(all.. or vnf-initiation[default]) :${normal}" c_vfn_name


  if [[ -z $c_vfn_name ]]; then
    c_vfn_name='vnf-initiation'
  fi

  c_vfn_testing='1'
  #if [ "$c_vfn_name" != "all" -a "$c_vfn_name"=="vnf-initiation" ]; then
  read -p "${bold}If you chose vnf-initiation, how many times do you testing?(number or 1[default]) :${normal}" c_vfn_testing
  if [ -z $c_vfn_testing ]; then
    c_vfn_testing='1'
  fi
  #fi

  c_vnf_names=($c_vfn_name)
  if [ "${#c_vnf_names[@]}" -gt 1 ]; then

    read -p "${bold}Do you want to proceed with deletion only?(y or n[default]) :${normal}" c_vfn_delete
    if [ -z $c_vfn_delete ]; then
        c_vfn_delete='n'
    fi

    for cnt in $(seq 1 $c_vfn_testing)
    do
      vnf_total_cnt=0
      vnf_list_str=""
      vnf_create_str="kubectl create"
      vnf_delete_str=""
      for vnf_name in ${c_vnf_names[@]}
      do
        is_c_vnf=$(kubectl get pods --all-namespaces | grep -o $vnf_name | grep -v NAME | wc -l)
        if [ $is_c_vnf -gt 0 ]; then
          vnf_delete_str="$vnf_delete_str $vnf_name"
        fi    
        vnf_total_cnt=$((vnf_total_cnt + 1))
        vnf_list_str="$vnf_list_str $vnf_name"
        vnf_create_str="$vnf_create_str -f $vnf_name.yaml"
      done
         
      if [ "$vnf_delete_str" != "" ]; then
        kubectl -n vicsnet delete pod $vnf_delete_str
        sleep 20
        for vnf_name in ${vnf_list_str[@]}
        do
          DEL_PORT=$(openstack port list | grep "vicsnet/$vnf_name" | awk '/ / {print $2}')
          if [ "$DEL_PORT" != "" ]; then
            openstack port delete ${DEL_PORT[@]}
          fi
        done
      fi
      
      if [ $c_vfn_delete == 'y' ]; then
        echo "${bold}C-VNF deletion has been completed.${normal}"
        exit 0
      fi
	  
      if [ "$vnf_list_str" == "" ]; then
        echo "${bold}There is no vnfd for the container.${normal}"
        exit 0
      fi
       
      sleep 1
      echo ""
      echo "${bold} == Create ${c_vnf_names[@]} ICN+DTM C-VNF == ${normal}"
      #echo $vnf_create_str
      $vnf_create_str
      sleep 2
      start_time="$(date -u +%s)"
      
      for i in {1..500}
      do
        #is_running_cnt=$(kubectl -n vicsnet get pods $vnf_list_str | grep -o Running | wc -l)
        is_running_cnt=$(kubectl -n vicsnet get pods ${c_vnf_names[@]} | grep -v 'NAME' | grep -o Running | wc -l)
        end_time="$(date -u +%s)"
        elapsed="$(($end_time-$start_time))"
      
        if [[ "$vnf_total_cnt" -eq "$is_running_cnt" ]]; then
          echo "The ICN+DTN CVNF(total_vnf: $vnf_total_cnt, running_vnf: $is_running_cnt) elapsed time : $elapsed(s)"
          break;
        fi
      
        echo "The ICN+DTN CVNF(total_vnf: $vnf_total_cnt, running_vnf: $is_running_cnt) elapsed time : $elapsed(s)"
        sleep 1
      done
	  
      # Routing testing
      # port error
      # openstack port list | grep vicsnet | grep DOWN | awk '/ / {print $2,$4,$6,$8,$11}'
      # openstack port list | grep 'vicsnet/' | grep DOWN | awk '/ / {print $2,$4,$6,$8,$11}'
      # openstack port delete $(openstack port list | grep 'vicsnet/' | grep DOWN | awk '/ / {print $2}')
      if [[ "$vnf_total_cnt" -eq "$is_running_cnt" ]]; then
        target_ndnping_prefix=$(kubectl -n vicsnet exec ${c_vnf_names[0]} -- bash -c 'grep prefix\ \/ndn\/korea /usr/local/etc/ndn/nlsr.conf | head -1 | awk "{print \$2}"')
        echo ""
        echo "${bold}Start routing test (${c_vnf_names[0]} to ${c_vnf_names[-1]})${normal}"
        start_time="$(date -u +%s)"
        
        ## start ndnping server
        kubectl -n vicsnet exec -it ${c_vnf_names[0]} \
          env target_ndnping_prefix=$target_ndnping_prefix \
          env start_vnf=${c_vnf_names[0]} \
          env end_vnf=${c_vnf_names[-1]} \
          -- /bin/bash -c \
'
ndnping_prefix="$target_ndnping_prefix/ping"
cd /root
pid=$(ps -ef | grep ndnpingserver | grep -v grep | awk "{ print \$2 }")
if [ "$pid" != "" ]; then
  kill -9 $pid
fi
sleep 1

echo -e "\033[1m  1. Waiting for configuration by cold-start of $start_vnf VNF\033[0m"
for i in {1..100}
do
  pid=$(ps -ef | grep "nlsr\ " | grep -v grep | awk "{ print \$2 }")
  if [ "$pid" != "" ]; then
    for i in {1..100}
    do
      sleep 1
      is_nlsr=$(nlsrc routing | grep -v grep | grep NexthopList | wc -l)
      if [ $is_nlsr -gt 0 ]; then
        echo -e "\033[1m  1.1. Starting ndnpingserver at $start_vnf :\033[0m prefix => $ndnping_prefix"
        #ndnpingserver $ndnping_prefix 1> ndnpingserver.out 2>&1 &
        nohup ndnpingserver $ndnping_prefix > ndnpingserver.out 2> ndnpingserver.err < /dev/null &
    echo -e "\033[1m  1.2. precess => $(ps -ax | grep ndnpingserver | grep -v grep)\033[0m"
        break
      fi
    done
    break
  fi
  sleep 1
done
'
        echo ""
        kubectl -n vicsnet exec -it ${c_vnf_names[-1]} \
          env target_ndnping_prefix=$target_ndnping_prefix \
          env start_vnf=${c_vnf_names[0]} \
          env end_vnf=${c_vnf_names[-1]} \
          -- /bin/bash -c \
'
cd /root
ndnping_prefix="$target_ndnping_prefix/ping"
for i in {1..100}
do
  ndn_ping_data=$(ndnping "$ndnping_prefix" | head -n 2 | grep -v PING)
  #ping_data=$(ping -c 1 vm-vnf | grep "from vm-vnf")
  is_ping=$(echo $ndn_ping_data | grep content | wc -l)  

  #echo -e "\033[1m  2. Connect from $end_vnf to $start_vnf VNF by ping :\033[0m $ping_data"
  if [ $is_ping -gt 0 ]; then
    echo -e "\033[1m  2. Connect from $end_vnf to $start_vnf VNF by ndn ping :\033[0m $ndn_ping_data"
    break;
  else
    echo -e "\033[1m  2. Connect from $end_vnf to $start_vnf VNF by ndn ping :\033[0m $ndn_ping_data"
  fi
  sleep 1
done # in {1..100}
'
        end_time="$(date -u +%s)"
        r_elapsed="$(($end_time+3-$start_time))"
        kubectl -n vicsnet exec -it ${c_vnf_names[0]} -- /bin/bash -c \
'
pid=$(ps -ef | grep ndnpingserver | grep -v grep | awk "{ print \$2 }")
if [ "$pid" != "" ]; then
  kill -9 $pid
fi
'
      fi # Routing testing
  
      echo ""
      echo "${bold}The ICN+DTN CVNF creation and routing time : $elapsed(s), $r_elapsed(s)${normal}"
      ##kubectl -n vicsnet get pods
    done # for cnt in $(seq 1 $c_vfn_testing)

  elif [ "$c_vfn_name" == 'all' ]; then
    read -p "${bold}Do you want to proceed with deletion only?(y or n[default]) :${normal}" c_vfn_delete
    if [ -z $c_vfn_delete ]; then
      c_vfn_delete='n'
    fi

    for cnt in $(seq 1 $c_vfn_testing)
    do
      vnf_total_cnt=0
      vnf_list_str=""
      vnf_create_str="kubectl create"
      vnf_delete_str=""
      for vnf_name in ${file_array[@]}
      do
        #if [ "$vnf_name" != "vnf-initiation" ] && [[ ! "$vnf_name" =~ "-mule" ]]; then
        if [[ "$vnf_name" != "vnf-initiation" ]] && [[ "$vnf_name" != *"-mule" ]] && [[ "$vnf_name" != *"-route" ]]; then
          is_c_vnf=$(kubectl get pods --all-namespaces | grep -oE "vicsnet.*$vnf_name" | grep -vE '*-initiation|*-mule' | wc -l)
          if [ $is_c_vnf -gt 0 ]; then
            vnf_delete_str="$vnf_delete_str $vnf_name"
          fi    
          vnf_total_cnt=$((vnf_total_cnt + 1))
          vnf_list_str="$vnf_list_str $vnf_name"
          vnf_create_str="$vnf_create_str -f $vnf_name.yaml"
        fi
      done
           
      if [ "$vnf_delete_str" != "" ]; then
        kubectl -n vicsnet delete pod $vnf_delete_str
        #for i in {1..100}
        #do
        #  sleep 1
        #  is_c_vnf=$(kubectl get pods --all-namespaces | grep -oE "vicsnet.*$vnf_name" | grep -vE '*-initiation|*-mule' | wc -l) 
        #  if [ $is_c_vnf -eq 0 ]; then
        #    break
        #  fi
        #done
        sleep 20
        for vnf_name in ${vnf_list_str[@]}
        do
          DEL_PORT=$(openstack port list | grep "vicsnet/$vnf_name" | awk '/ / {print $2}')
    	  if [ "$DEL_PORT" != "" ]; then
            openstack port delete ${DEL_PORT[@]}
    	  fi
        done
      fi
      
      if [ $c_vfn_delete == 'y' ]; then
        echo "${bold}C-VNF deletion has been completed.${normal}"
        exit 0
      fi
      
      if [ "$vnf_list_str" == "" ]; then
        echo "${bold}There is no vnfd for the container.${normal}"
        exit 0
      fi
       
      sleep 1
      echo ""
      echo "${bold} == Create all ICN+DTM C-VNF == ${normal}"
      #echo $vnf_create_str
      $vnf_create_str
      sleep 2
      start_time="$(date -u +%s)"
       
      for i in {1..500}
      do
        #is_running_cnt=$(kubectl -n vicsnet get pods $vnf_list_str | grep -o Running | wc -l)
        is_running_cnt=$(kubectl -n vicsnet get pods | grep -vE 'vnf-initiation|-mule|dashboard' | grep -o Running | wc -l)
        end_time="$(date -u +%s)"
        elapsed="$(($end_time+3-$start_time))"
      
        if [[ "$vnf_total_cnt" -eq "$is_running_cnt" ]]; then
          echo "The all ICN+DTN CVNF(total_vnf: $vnf_total_cnt, running_vnf: $is_running_cnt) elapsed time : $elapsed(s)"
          break;
        fi
      
        echo "The all ICN+DTN CVNF(total_vnf: $vnf_total_cnt, running_vnf: $is_running_cnt) elapsed time : $elapsed(s)"
        sleep 1
      done
	  
      # Routing testing
      # port error
      # openstack port list | grep vicsnet | grep DOWN | awk '/ / {print $2,$4,$6,$8,$11}'
      # openstack port list | grep 'vicsnet/' | grep DOWN | awk '/ / {print $2,$4,$6,$8,$11}'
      # openstack port delete $(openstack port list | grep 'vicsnet/' | grep DOWN | awk '/ / {print $2}')
      if [[ "$vnf_total_cnt" -eq "$xis_running_cnt" ]]; then
        echo ""
        echo "${bold}Start routing test (dongjak-hu1 to seongnam-hu1)${normal}"
        start_time="$(date -u +%s)"
        ## start ndnping server
        kubectl -n vicsnet exec -it seongnam-hu1 -- /bin/bash -c \
'
ndnping_prefix="/ndn/korea/gyeonggi/seongnam/hospital/unit1/ping"
cd /root
pid=$(ps -ef | grep ndnpingserver | grep -v grep | awk "{ print \$2 }")
if [ "$pid" != "" ]; then
  kill -9 $pid
fi
sleep 1

echo -e "\033[1m  1. Waiting for configuration by cold-start of seongnam-hu1 VNF\033[0m"
for i in {1..100}
do
  pid=$(ps -ef | grep "nlsr\ " | grep -v grep | awk "{ print \$2 }")
  if [ "$pid" != "" ]; then
    for i in {1..100}
    do
      sleep 1
      is_nlsr=$(nlsrc routing | grep -v grep | grep NexthopList | wc -l)
      if [ $is_nlsr -gt 0 ]; then
        echo -e "\033[1m  1.1. Starting ndnpingserver at seongnam-hu1 :\033[0m prefix => $ndnping_prefix"
        #ndnpingserver $ndnping_prefix 1> ndnpingserver.out 2>&1 &
        nohup ndnpingserver $ndnping_prefix > ndnpingserver.out 2> ndnpingserver.err < /dev/null &
    echo -e "\033[1m  1.2. precess => $(ps -ax | grep ndnpingserver | grep -v grep)\033[0m"
        break
      fi
    done
    break
  fi
  sleep 1
done
'
        kubectl -n vicsnet exec -it dongjak-pu1 -- /bin/bash -c \
'
cd /root
ndnping_prefix="/ndn/korea/gyeonggi/seongnam/hospital/unit1/ping"
for i in {1..100}
do
  ndn_ping_data=$(ndnping "$ndnping_prefix" | head -n 2 | grep -v PING)
  #ping_data=$(ping -c 1 vm-vnf | grep "from vm-vnf")
  is_ping=$(echo $ndn_ping_data | grep content | wc -l)  

  echo ""
  #echo -e "\033[1m  2. Connect from dongjak-pu1 to seongnam-hu1 VNF by ping :\033[0m $ping_data"
  if [ $is_ping -gt 0 ]; then
    echo -e "\033[1m  2. Connect from dongjak-pu1 to seongnam-hu1 VNF by ndn ping :\033[0m $ndn_ping_data"
    break;
  else
    echo -e "\033[1m  2. Connect from dongjak-pu1 to seongnam-hu1 VNF by ndn ping :\033[0m $ndn_ping_data"
  fi
  sleep 1
done # in {1..100}
'
        end_time="$(date -u +%s)"
        r_elapsed="$(($end_time+3-$start_time))"        
        kubectl -n vicsnet exec -it seongnam-hu1 -- /bin/bash -c \
'
pid=$(ps -ef | grep ndnpingserver | grep -v grep | awk "{ print \$2 }")
if [ "$pid" != "" ]; then
  kill -9 $pid
fi
'
      fi # Routing testing

  
      echo ""
      echo "${bold}The all ICN+DTN CVNF($c_vfn_name) creation and routing time : $elapsed(s), $r_elapsed(s)${normal}"
      #kubectl -n vicsnet get pods
      #echo "$(kubectl -n vicsnet get pods $vnf_list_str)"
    done # for cnt in $(seq 1 $c_vfn_testing)
  
  else # if [ $c_vfn_name != 'all' ]  and if [ "${#c_vnf_names[@]}" -lt < 1 ] 
       # vnf-initiation test or only one vnf create/delete test
    read -p "${bold}Do you want to proceed with deletion only?(y or n[default]) :${normal}" c_vfn_delete
    if [ -z $c_vfn_delete ]; then
        c_vfn_delete='n'
    fi

    total_time=0
    elapsed_data=()
    start_data=()
    end_data=()	
    for cnt in $(seq 1 $c_vfn_testing)
    do
      sleep 1
      echo "${bold}Begin $cnt testing...${normal}"
      is_c_vnf=$(kubectl -n vicsnet get pods | grep $c_vfn_name | wc -l)
      
      if [ $is_c_vnf -gt '0' ]; then
        kubectl -n vicsnet delete pod $c_vfn_name
        sleep 2

        DEL_PORT=$(openstack port list | grep "vicsnet/$c_vfn_name" | awk '/ / {print $2}')
        if [ "$DEL_PORT" != "" ]; then
          openstack port delete ${DEL_PORT[@]}
    	fi

        if [ $c_vfn_delete == 'y' ]; then
          echo "${bold}C-VNF deletion has been completed.${normal}"
          exit 0
        fi
      fi
      
      echo ""
      echo "${bold} == Create ICN+DTM C-VNF == ${normal}"
      kubectl -n vicsnet create -f $c_vfn_name.yaml
      
      vnf_status_pre=""
      for i in {1..100}
      do
        vnf_status=$(kubectl -n vicsnet get pods $c_vfn_name | grep $c_vfn_name | awk '/  / {print $3}')
          if [ "$vnf_status_pre" != "$vnf_status" ]; then
          echo "c-vnd-name: $c_vfn_name, status: ${bold}$vnf_status${normal}"
          fi
        if [[ $vnf_status == "Running" ]]; then
          break;
        fi
        sleep 1
        vnf_status_pre=$vnf_status
      done # in {1..100}
      
      #startTime=$(kubectl -n vicsnet get pods $c_vfn_name -o jsonpath='{.status.startTime}')
      #startedAt=$(kubectl -n vicsnet get pods $c_vfn_name -o jsonpath='{.status.containerStatuses[*]...startedAt}')
      start_end=$(kubectl -n vicsnet get pods $c_vfn_name -o jsonpath='{.status.startTime}|{.status.containerStatuses[*]...startedAt}')
      start_end_arry=(${start_end//|/ })
      
      echo ""
      echo "startTime: ${start_end_arry[0]}"
      echo "startedAt: ${start_end_arry[1]}"
      
      start_time="$(date -d"${start_end_arry[0]}" +%s)"
      end_time="$(date -d"${start_end_arry[1]}" +%s)"
      elapsed="$(($end_time-$start_time))"
      
      total_time="$(($elapsed+$total_time))"
      average_time=$(printf %.1f\\n "$((10**1 * $total_time/$cnt))e-1")

      echo ""
      echo "${bold}The ICN+DTN CVNF($c_vfn_name) creation time : a number of c-vnf($cnt), $elapsed(s)${normal}"
      elapsed_data+=("$elapsed")
      start_data+=("${start_end_arry[0]}")
      end_data+=("${start_end_arry[1]}")
      #echo "${bold}The ICN+DTN CVNF($c_vfn_name) total time(avg) : a number of c-vnf($cnt), average time $average_time(s){normal}"
      echo ""
      #kubectl -n vicsnet get pods $c_vfn_name      
    done # for cnt in $(seq 1 $c_vfn_testing)

    echo "+-----------+-------------------+"
    echo "|   Count   | Elapsed Time (sec)|"
    for key in ${!elapsed_data[@]}
    do
      key_pad=$(printf "%03d" $(($key+1)))
      elapsed_pad=$(printf "%03d" ${elapsed_data[$key]})
      echo "+-----------+-------------------+"
      echo "|    $key_pad    |       $elapsed_pad(s)      |"
    done
    total_cnt=$(printf "%03d" ${#elapsed_data[@]})
    average_t=$(printf "%05.1f" $average_time)
    
    echo "+-----------+-------------------+"
    echo "+-----------+-------------------+"
    echo "|Total Count| Average Time(sec) |"
    echo "+-----------+-------------------+"
    echo "|    $total_cnt    |      $average_t(s)     |"
    echo "+-----------+-------------------+"
  fi
  popd
fi
