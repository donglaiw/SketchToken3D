#!/bin/bash

# Finds which machine has an open slot and submits the job
#   NOTE: should be called within a big loop, not directly

shopt -s expand_aliases
SERVICE=${1}
MACHINE_ID=${2}
if [ -z "${MACHINE_ID}" ]; then
    MACHINE_ID=0
fi

MACHINENAME="noneAvailable"
NUMOPEN=0
HOSTNAME=`hostname`

#while [ "${MACHINENAME}" == "noneAvailable" ]; do
while true;do
   username=`whoami`
   list=`./para/p_machine.sh`
   list2=( $list )

   if [ ${MACHINE_ID} -ge $((${#list2[@]})) ];then
       MACHINE_ID=0
   fi
   for (( i=${MACHINE_ID};i<${#list2[@]};i++)); do
      if [ $[${i}%3] == 0 ]; then
         if [ ${list2[${i}]} = ${HOSTNAME} ]; then
             # nonzero cpu usage
             NUMCPU=`top -bn 1 | awk '{print $9}' | tail -n +8 | awk '{s+=$1} END {print s}'`
             NUMRUNNING1=$(($NUMCPU/100))
             NUMRUNNING2=`ps aux | grep -v grep | grep -v p_check | grep ${SERVICE} | grep -v ssh | grep -v bash | grep -v '\[' |wc -l`
             NUMRUNNING2=$(($NUMRUNNING2/2))
             NUMRUNNING=$(($NUMRUNNING1>$NUMRUNNING2?$NUMRUNNING1:$NUMRUNNING2))
            #NUMRUNNING=`ps -ef | grep -v grep | grep -v p_check | grep ${SERVICE} | grep -v dmlworker | grep -v ssh | grep -v bash | grep -v '\[' | tr -s ' '| cut -d ' ' -f 4| grep -v 0 |  wc -l`
            #NUMRUNNING=`ps -ef | grep -v grep | grep -v p_check | grep ${SERVICE} | grep -v ssh | grep -v bash | grep -v '\[' | tr -s ' '| cut -d ' ' -f 4| grep -v 0 |  wc -l`
            #NUMRUNNING=`ps -ef | grep -v grep | grep -v p_check | grep ${SERVICE} | grep -v anyport | grep -v ssh | grep -v bash | wc -l`
            #Nm=`ps -ef | grep -v grep | grep -v p_check | grep MATLAB | grep -v anyport | grep -v ssh | grep -v bash | wc -l`
            #Np=`ps -ef | grep -v grep | grep -v p_check | grep python | grep -v anyport | grep -v ssh | grep -v bash | wc -l`
            #NUMRUNNING=$((${Nm}+${Np}))
         else
             NUMCPU=`ssh ${list2[${i}]} top -bn 1 | awk '{print $9}' | tail -n +8 | awk '{s+=$1} END {print s}'`
             NUMRUNNING1=$(($NUMCPU/100))
             NUMRUNNING2=`ssh ${list2[${i}]} "ps aux | grep -v grep | grep -v p_check | grep ${SERVICE} | grep -v anyport | grep -v ssh | grep -v bash | grep -v '\['| wc -l"`
             NUMRUNNING2=$(($NUMRUNNING2/2))
             NUMRUNNING=$(($NUMRUNNING1>$NUMRUNNING2?$NUMRUNNING1:$NUMRUNNING2))
            #NUMRUNNING=`ssh ${list2[${i}]} "ps -ef | grep -v grep | grep -v p_check | grep ${SERVICE} | grep -v dmlworker | grep -v anyport | grep -v ssh | grep -v bash | grep -v '\['|  tr -s ' '| cut -d ' ' -f 4| grep -v 0 | wc -l"`
            #NUMRUNNING=`ssh ${list2[${i}]} "ps -ef | grep -v grep | grep -v p_check | grep ${SERVICE} | grep -v anyport | grep -v ssh | grep -v bash | grep -v '\['|  tr -s ' '| cut -d ' ' -f 4| grep -v 0 | wc -l"`
            #NUMRUNNING=`ssh ${list2[${i}]} "ps -ef | grep -v grep | grep -v p_check | grep ${SERVICE} | grep -v anyport | grep -v ssh | grep -v bash | wc -l"`
            #Nm=`ssh ${list2[${i}]} "ps -ef | grep -v grep | grep -v p_check | grep MATLAB | grep -v anyport | grep -v ssh | grep -v bash | wc -l"`
            #Np=`ssh ${list2[${i}]} "ps -ef | grep -v grep | grep -v p_check | grep python | grep -v anyport | grep -v ssh | grep -v bash | wc -l"`
            #NUMRUNNING=$((${Nm}+${Np}))
         fi
         j=$[${i}+1]
         #echo "${NUMRUNNING}--${list2[$j]}"
         #$[${i}+1]
         if [ ${NUMRUNNING} -lt ${list2[$j]} ]; then
            MACHINENAME=${list2[${i}]}
            NUMOPEN=$((${list2[$j]}-${NUMRUNNING}))
            MACHINE_ID=${i}
            break 2
         fi
      fi
	done
    MACHINE_ID=0
done

echo "${MACHINENAME} ${NUMOPEN} ${MACHINE_ID}"
