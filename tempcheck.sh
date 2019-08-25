#!/bin/bash
#
#  versao 1.1
#
#  NOME
#    tempcheck.sh
#
#  AUTOR
#    Matheus Barzon (email)
#
#  DESCRICAO
#    This script read the temperature of RasPi and underclocking it or shutting down it
#
#  NOTA
#    80ºC is the maximum temperature allowed on RasPi
#
#


LOCK="/tmp/tempcheck.lock"

if [ -e ${LOCK} ] ; then
  echo -e "Fail to check the temperature of SoC. Another process is running:\n\n"
  exit 1
fi

touch ${LOCK}


SENSOR="$(vcgencmd measure_temp | cut -d "=" -f2 | cut -d "'" -f1 | cut -d '.' -f1)"
CURRENT_TEMP="$(printf "%.0f\n" ${SENSOR})"

MAX_FREQ="/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"
MIN_FREQ="/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq"
BKP_MAX_FREQ="/var/backups/scaling_max_freq_bkp"

MAX_TEMP="78"
ALERT_TEMP="70"

if [ ! -e "${BKP_MAX_FREQ}" ] ; then
  cp "${MAX_FREQ}" "${BKP_MAX_FREQ}"
fi

if [ "${CURRENT_TEMP}" -gt "${MAX_TEMP}" ] ; then
  echo "${CURRENT_TEMP}ºC is too hot!"
  /usr/bin/logger "Shutting down due to SoC temp ${CURRENT_TEMP}."

  rm ${LOCK}
  /sbin/shutdown -h now
elif [ "${CURRENT_TEMP}" -gt "${ALERT_TEMP}" ] ; then
  SENSOR="$(vcgencmd measure_temp | cut -d "=" -f2)"

  chmod 755 "${MAX_FREQ}"
  echo `cat ${MIN_FREQ}` > "${MAX_FREQ}"
  chmod 644 "${MAX_FREQ}"
  
  rm ${LOCK}
  exit 0
else
  if [ `cat ${MAX_FREQ}` -lt "1400000" ] ; then
    chmod 755 "${MAX_FREQ}"
    if [ -e "${BKP_MAX_FREQ}" ] ; then
      echo `cat ${BKP_MAX_FREQ}` > "${MAX_FREQ}"
    else
      echo "1400000" > "${MAX_FREQ}"
    fi
    chmod 644 "${MAX_FREQ}"
  fi

  rm ${LOCK}
  exit 0
fi
