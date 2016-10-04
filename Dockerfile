FROM ubuntu
MAINTAINER Alexey Astafev "efsneiron@gmail.com"

ENV PHP_DEPS php7.0-cli php7.0-curl php7.0-fpm php7.0-mysql php7.0-gd php7.0-mcrypt php7.0-intl php7.0-xml
ENV INI_CONF=/etc/php/7.0

RUN apt-get update \
	&& apt-get install -y $PHP_DEPS \
	&& rm -rf /var/lib/apt/lists/*

RUN rm $INI_CONF/fpm/php.ini && ln -s $INI_CONF/cli/php.ini $INI_CONF/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = Europe\/Moscow/" $INI_CONF/cli/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" $INI_CONF/cli/php.ini
RUN mkdir -p /run/php
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/local/bin
RUN php -r "unlink('composer-setup.php');"

COPY www.conf $INI_CONF/fpm/pool.d/

EXPOSE 9000

CMD ["/usr/sbin/php-fpm7.0", "-F"]