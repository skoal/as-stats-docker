FROM bitnami/minideb:stretch

RUN mkdir /as-stats
ADD AS-Stats /as-stats/
WORKDIR /as-stats

### Dependecies

RUN apt update \
    && apt install -y supervisor nginx curl perl rrdtool librrds-perl libdbi-perl make gcc git php-fpm php7.0-sqlite3 ttf-dejavu tzdata cpanminus cron 

RUN cpanm File::Find::Rule Net::sFlow Text::Glob Number::Compare Net::Patricia JSON::XS 

COPY files/perl-ip2as/ip2as.pm /usr/share/perl5/ip2as.pm

### NGINX + PHP-FPM

COPY files/nginx/nginx.conf /etc/nginx/nginx.conf
ADD files/nginx/asstats.conf /etc/nginx/sites-available/asstats.conf
RUN rm -f /etc/nginx/sites-enabled/default
RUN ln -s /etc/nginx/sites-available/asstats.conf /etc/nginx/sites-enabled/asstats.conf
RUN mkdir -p /run/php

EXPOSE 8010:80/tcp
EXPOSE 5000:5000/udp

ENV TZ=Europe/Budapest
ENV NETFLOW=1
ENV NETFLOW_PORT=5000
ENV SFLOW=0

VOLUME ["/data/as-stats"]

COPY files/cron/as-stats /etc/cron.d

ADD files/stats-day.sh /usr/sbin/stats-day
RUN chmod +x /usr/sbin/stats-day

ADD files/startup.sh /
RUN chmod +x /startup.sh

ADD files/supervisord.conf /etc/supervisord.conf

CMD /usr/bin/supervisord -c /etc/supervisord.conf
