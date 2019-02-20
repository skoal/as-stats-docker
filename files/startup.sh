#!/bin/bash

if [ ! -d /data/as-stats/conf ]; then
    mkdir -p /data/as-stats/conf
fi

if [ ! -d /data/as-stats/rrd ]; then
    mkdir -p /data/as-stats/rrd
fi

if [ -n $TZ ] ; then
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ > /etc/timezone
else
  ln -snf /usr/share/zoneinfo/UTC /etc/localtime
  echo UTC > /etc/timezone
fi

# persistante config file web ui
if [ -f /data/as-stats/conf/config.inc ] ; then
  rm /as-stats/www/config.inc
  ln -nfs /data/as-stats/conf/config.inc /as-stats/www/config.inc
else
  mv /as-stats/www/config.inc /data/as-stats/conf/config.inc
  ln -nfs /data/as-stats/conf/config.inc /as-stats/www/config.inc
fi

if [[ $NETFLOW == 1 && $SFLOW != 1 ]] ; then
  nohup /as-stats/bin/asstatd.pl -r /data/as-stats/rrd -k /data/as-stats/conf/knownlinks -P0 -p $NETFLOW_PORT &
elif [[ $SFLOW == 1 && $NETFLOW != 1 ]] ;  then
  nohup /as-stats/bin/asstatd.pl -r /data/as-stats/rrd -k /data/as-stats/conf/knownlinks -P $SFLOW_PORT -a $SFLOW_ASN -p 0 &
elif [[ $NETFLOW == 1 && $SFLOW == 1 ]] ;  then
  nohup /as-stats/bin/asstatd.pl -r /data/as-stats/rrd -k /data/as-stats/conf/knownlinks -P $SFLOW_PORT -a $SFLOW_ASN -p $NETFLOW_PORT &
fi

# start first data to generate asstats_day.txt - wait 2 minutes
sleep 120
/as-stats/bin/rrd-extractstats.pl /data/as-stats/rrd /data/as-stats/conf/knownlinks /data/as-stats/asstats_day.txt
