FROM ubuntu:22.04

ARG OLS_VERSION
ARG PHP_VERSION


ADD https://repo.litespeed.sh repo.litespeed.sh
ADD https://openlitespeed.org/packages/openlitespeed-"$OLS_VERSION".tgz openlitespeed-"$OLS_VERSION".tgz


RUN apt update && apt install curl cron tzdata -y && \
  chmod +x repo.litespeed.sh && ./repo.litespeed.sh && rm repo.litespeed.sh && \
  tar xzf openlitespeed-"$OLS_VERSION".tgz && cd openlitespeed && ./install.sh && \
  echo 'cloud-docker' > /usr/local/lsws/PLAT && rm -rf /openlitespeed && rm /openlitespeed-"$OLS_VERSION".tgz && \
  apt install mysql-client "$PHP_VERSION" "$PHP_VERSION"-common "$PHP_VERSION"-mysql "$PHP_VERSION"-opcache \
  "$PHP_VERSION"-curl "$PHP_VERSION"-imagick "$PHP_VERSION"-redis "$PHP_VERSION"-memcached "$PHP_VERSION"-intl -y && \
  bash -c 'if [[ "$PHP_VERSION" == lsphp7* ]]; then apt install "$PHP_VERSION"-json -y; fi' && \
  apt clean

# RUN wget -O /usr/local/lsws/admin/misc/lsup.sh \
#   https://raw.githubusercontent.com/litespeedtech/openlitespeed/master/dist/admin/misc/lsup.sh && \
#   chmod +x /usr/local/lsws/admin/misc/lsup.sh
ADD https://raw.githubusercontent.com/litespeedtech/openlitespeed/master/dist/admin/misc/lsup.sh /usr/local/lsws/admin/misc/lsup.sh
RUN chmod +x /usr/local/lsws/admin/misc/lsup.sh

# RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
#   chmod +x wp-cli.phar && mv wp-cli.phar /usr/bin/wp && \
#   ln -s /usr/local/lsws/$PHP_VERSION/bin/php /usr/bin/php
ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar wp-cli.phar
RUN chmod +x wp-cli.phar && mv wp-cli.phar /usr/bin/wp && ln -s /usr/local/lsws/"$PHP_VERSION"/bin/php /usr/bin/php

# RUN wget -O -  https://get.acme.sh | sh
ADD https://get.acme.sh get.acme.sh
RUN chmod +x get.acme.sh && ./get.acme.sh && rm get.acme.sh

EXPOSE 7080
ENV PATH="/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"

COPY docker.conf /usr/local/lsws/conf/templates/docker.conf
COPY setup_docker.sh /usr/local/lsws/bin/setup_docker.sh
COPY httpd_config.xml /usr/local/lsws/conf/httpd_config.xml
COPY htpasswd /usr/local/lsws/admin/conf/htpasswd

RUN /usr/local/lsws/bin/setup_docker.sh && rm /usr/local/lsws/bin/setup_docker.sh && \
  chown 999:999 /usr/local/lsws/conf -R && \
  cp -RP /usr/local/lsws/conf/ /usr/local/lsws/.conf/ && \
  cp -RP /usr/local/lsws/admin/conf /usr/local/lsws/admin/.conf/ && \
  bash -c 'if [[ "$PHP_VERSION" == lsphp8* ]]; then ln -sf /usr/local/lsws/"$PHP_VERSION"/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp8; fi' && \
  bash -c 'if [[ "$PHP_VERSION" == lsphp8* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp8 /usr/local/lsws/fcgi-bin/lsphp; fi' && \
  bash -c 'if [[ "$PHP_VERSION" == lsphp7* ]]; then ln -sf /usr/local/lsws/"$PHP_VERSION"/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp7; fi' && \
  bash -c 'if [[ "$PHP_VERSION" == lsphp7* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp7 /usr/local/lsws/fcgi-bin/lsphp; fi'
# #RUN sed -i "s|fcgi-bin/lsphp|/usr/local/lsws/$PHP_VERSION/bin/lsphp|g" /usr/local/lsws/conf/httpd_config.conf
# RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp8* ]]; then ln -sf /usr/local/lsws/$PHP_VERSION/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp8; fi"]
# RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp8* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp8 /usr/local/lsws/fcgi-bin/lsphp; fi"]
# RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then ln -sf /usr/local/lsws/$PHP_VERSION/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp7; fi"]
# RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp7 /usr/local/lsws/fcgi-bin/lsphp; fi"]
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /var/www/vhosts/
