FROM ubuntu
MAINTAINER Alexey Astafev "efsneiron@gmail.com"

ENV PHP_DEPS php7.0-cli php7.0-curl php7.0-fpm php7.0-mysql php7.0-gd php7.0-mcrypt php7.0-intl
ENV INI_CONF=/etc/php/7.0

RUN apt-get update \
	&& apt-get install -y $PHP_DEPS php-xdebug curl \
	&& rm -rf /var/lib/apt/lists/*

RUN rm $INI_CONF/fpm/php.ini && ln -s $INI_CONF/cli/php.ini $INI_CONF/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = Europe\/Moscow/" $INI_CONF/cli/php.ini
RUN sed -i "s/upload_max_filesize =.*/upload_max_filesize = 50M/" $INI_CONF/cli/php.ini
RUN sed -i "s/post_max_size =.*/post_max_size = 50M/" $INI_CONF/cli/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" $INI_CONF/cli/php.ini
RUN sed -i "s/display_errors = Off/display_errors = On/" $INI_CONF/cli/php.ini
RUN sed -i "s/display_startup_errors = Off/display_startup_errors = On/" $INI_CONF/cli/php.ini
RUN mkdir -p /run/php

COPY www.conf $INI_CONF/fpm/pool.d/
COPY xdebug.ini $INI_CONF/mods-available/

EXPOSE 9000 9010

CMD ["/usr/sbin/php-fpm7.0", "-F"]