FROM bitnami/minideb:stretch

RUN apt update
RUN apt install -y supervisor nginx bash curl perl rrdtool make librrdtool-oo-perl git php-fpm ttf-dejavu tzdata 

# libfile-find-object-perl 

WORKDIR /as-stats/

RUN curl --location http://search.cpan.org/CPAN/authors/id/R/RC/RCLAMP/File-Find-Rule-0.34.tar.gz | tar -xzf - \
    && cd File-Find-Rule-0.34/ \
    && perl Makefile.PL ; make ; make install

RUN curl --location http://search.cpan.org/CPAN/authors/id/E/EL/ELISA/Net-sFlow-0.11.tar.gz | tar -xzf - \
    && cd Net-sFlow-0.11/ \
    && perl Makefile.PL ; make ; make install

RUN curl --location http://search.cpan.org/CPAN/authors/id/R/RC/RCLAMP/Text-Glob-0.09.tar.gz | tar -xzf - \
    && cd Text-Glob-0.09/ \
    && perl Makefile.PL ; make ; make install

RUN curl --location  http://search.cpan.org/CPAN/authors/id/R/RC/RCLAMP/Number-Compare-0.03.tar.gz | tar -xzf - \
    && cd Number-Compare-0.03/ \
    && perl Makefile.PL ; make ; make install

RUN rm -Rf Net-sFlow-0.11 File-Find-Rule-0.34 Text-Glob-0.09 Number-Compare-0.03

RUN git clone https://github.com/manuelkasper/AS-Stats.git

RUN rm -Rf /var/www/localhost && \
    mv AS-Stats/www/* /var/www

### NGINX + PHP-FPM
RUN mkdir /run/nginx/
COPY nginx/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/nginx/sites-available/ && \
    mkdir -p /etc/nginx/sites-enabled/
ADD nginx/asstats.conf /etc/nginx/sites-available/asstats.conf
RUN ln -s /etc/nginx/sites-available/asstats.conf /etc/nginx/sites-enabled/asstats.conf

EXPOSE 80

VOLUME ["/data/as-stats"]

ADD files/cron.txt /root
RUN cat /root/cron.txt >> /etc/crontabs/root && rm /root/cron.txt

ADD files/stats-day.sh /usr/sbin/stats-day
RUN chmod +x /usr/sbin/stats-day

ADD files/startup.sh /root
ADD files/supervisord.conf /etc/supervisord.conf
RUN chmod +x /root/startup.sh
ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c",  "/etc/supervisord.conf"]
