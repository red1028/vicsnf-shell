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


  if [ -z $c_vfn_name ]; then
    c_vfn_name='vnf-initiation'
  fi

  c_vfn_testing='1'
  if [  $c_vfn_name != 'all' -a "$c_vfn_name"=="vnf-initiation" ]; then
    read -p "${bold}If you chose vnf-initiation, how many times do you testing?(number or 1[default]) :${normal}" c_vfn_testing
    if [ -z $c_vfn_testing ]; then
      c_vfn_testing='1'
    fi
  fi


  if [ $c_vfn_name == 'all' ]; then
  
    read -p "${bold}Do you want to proceed with deletion only?(y or n[default]) :${normal}" c_vfn_delete
    if [ -z $c_vfn_delete ]; then
    	c_vfn_delete='n'
    fi
  
    vnf_total_cnt=0
    vnf_list_str=""
    vnf_create_str="kubectl create"
    for vnf_name in ${file_array[@]}
    do
      #if [ "$vnf_name" != "vnf-initiation" ] && [[ ! "$vnf_name" =~ "-mule" ]]; then
      if [[ "$vnf_name" != "vnf-initiation" ]] && [[ "$vnf_name" != *"-mule" ]]; then
        is_c_vnf=$(kubectl get pods --all-namespaces | grep -oE "vicsnet.*$vnf_name" | grep -vE '*-initiation|*-mule' |wc -l)
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
	  sleep 10
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
    start_time="$(date -u +%s)"
  	sleep 2
     
    for i in {1..200}
    do
      #is_running_cnt=$(kubectl -n vicsnet get pods $vnf_list_str | grep -o Running | wc -l)
      is_running_cnt=$(kubectl -n vicsnet get pods | grep -vE 'vnf-initiation|-mule' | grep -o Running | wc -l)
      end_time="$(date -u +%s)"
      elapsed="$(($end_time+3-$start_time))"
    
      if [[ "$vnf_total_cnt" -eq "$is_running_cnt" ]]; then
        echo "The all ICN+DTN CVNF(total_vnf: $vnf_total_cnt, running_vnf: $is_running_cnt) elapsed time : $elapsed(s)"
        break;
      fi
    
      echo "The all ICN+DTN CVNF(total_vnf: $vnf_total_cnt, running_vnf: $is_running_cnt) elapsed time : $elapsed(s)"
  	  sleep 2
    done
  
    echo ""
    echo "${bold}The all ICN+DTN CVNF($c_vfn_name) creation time : $elapsed(s)${normal}"
    kubectl -n vicsnet get pods
    #echo "$(kubectl -n vicsnet get pods $vnf_list_str)"
  
  else # if [ "$is_process" = "y" -o "$is_process" = "Y" ]
  
	read -p "${bold}Do you want to proceed with deletion only?(y or n[default]) :${normal}" c_vfn_delete
	if [ -z $c_vfn_delete ]; then
		c_vfn_delete='n'
	fi

    for cnt in $(seq 1 $c_vfn_testing)
    do
      sleep 1
  	  echo "${bold}Begin $cntth testing...${normal}"
      is_c_vnf=$(kubectl -n vicsnet get pods | grep $c_vfn_name | wc -l)
      
      if [ $is_c_vnf -gt '0' ]; then
        kubectl -n vicsnet delete pod $c_vfn_name
        if [ $c_vfn_delete == 'y' ]; then
          echo "${bold}C-VNF deletion has been completed.${normal}"
          exit 0
        fi
  	    sleep 2
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
      
      echo ""
      echo "${bold}The ICN+DTN CVNF($c_vfn_name) creation time : $elapsed(s)${normal}"
      echo ""
      #kubectl -n vicsnet get pods $c_vfn_name
  	
    done # for cnt in $(seq 1 $c_vfn_testing)
  fi
  popd
fi
