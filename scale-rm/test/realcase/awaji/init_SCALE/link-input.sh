#!/bin/sh
################################################################################
# 2009/10/26 --- Ryuji Yoshida.
# 2014/07/08 --- Tsuyoshi Yamaura
################################################################################

nproc=16

################################################################################

indir="${SCALE_DB}/init_sample/SCALE_7.5km"

for np in `seq 1 ${nproc}`
do
   let "ip = ${np} - 1"
   PE=`printf %06d ${ip}`

   src=${indir}/history.pe${PE}.nc

   if [ -f ${src} ]; then
      if [ "${SCALE_SYS}" == "Kmicro" ]; then
         cp -vf  ${src} ./${dst}
      else
         ln -svf ${src} ./${dst}
      fi
   else
      echo "datafile does not found! : ${src}"
      exit 1
   fi
done

src=${indir}/latlon_domain_catalogue.txt

if [ -f ${src} ]; then
   if [ "${SCALE_SYS}" == "Kmicro" ]; then
      cp -vf  ${src} .
   else
      ln -svf ${src} .
   fi
else
   echo "datafile does not found! : ${src}"
   exit 1
fi
