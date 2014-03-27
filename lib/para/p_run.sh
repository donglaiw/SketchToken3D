#!/bin/bash

# batch converts images from one type to another
shopt -s expand_aliases

HOSTNAME=`hostname`
NUMOPEN=0
SERVICE="MATLAB"
DO=${1}
ITER1=${2}
ITER2=${3}
PP=${4}
COM1=${5}
COM2=${6}
COM3=${7}
CHECK1=${8}
CHECK2=${9}
NUMOPEN=0
MACHINE_ID=0
for (( ni=${ITER1}; ni<=${ITER2}; ni++ ))
do
   if [ -z $CHECK1 ]; then
       numfiles=0
    else
        numfiles=`ls ${CHECK1}${ni}${CHECK2} |wc -l`
   fi
   
   if [ ${numfiles} -eq 0 ];then
          # get an open computer and the number of processors it has
          if [ ${NUMOPEN} -le 0 ]; then
             sleep 2
             MACHINEINFO=`./para/p_check.sh ${SERVICE} ${MACHINE_ID}`
             b=($(echo $MACHINEINFO | tr " " "\n"))
             MACHINENAME=${b[0]}
             NUMOPEN=${b[1]}
             MACHINE_ID=${b[2]}                 
          fi
          CMD="cd ${PP} && ./matlabCMD.sh \"-nosplash -singleCompThread -nodesktop -r runScript('${COM1}','${COM2}${ni}${COM3}');\""
          echo $CMD
          # give it some sleep time for good measure
          sleep 0.2
          echo "${MACHINENAME} : ${NUMOPEN} "
          if [ $DO = "1" ]; then
              if [ ${MACHINENAME} = ${HOSTNAME} ]; then
                 eval "${CMD}" &
              else
                 ssh -x ${MACHINENAME} $CMD &
              fi
          fi

          #let NUMOPEN=NUMOPEN-1
          # for test
          NUMOPEN=0
          MACHINE_ID=$[${MACHINE_ID}+3]
  fi
done

