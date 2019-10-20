#!/bin/sh

if [ "$#" = "0" ]; then
	echo "$ Set_IP.sh ip"
	exit 1
fi

################################################# CONSTANT
cd `dirname $0`
THIS_FILE_LOCATION=$PWD
DDNS="${THIS_FILE_LOCATION}/DDNS"
ip=$1

for ddns in `ls ${DDNS}`
do
	echo "${DDNS}/${ddns}/${ddns}.sh ${ip}"
	"${DDNS}/${ddns}/${ddns}.sh" "${ip}"
done
