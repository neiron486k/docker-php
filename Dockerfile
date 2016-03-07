FROM debian:jessie
MAINTAINER Alexey Astafiev "efsneiron@gmail.com"
ENV PHP_DEPS php5-fpm php5-curl php5-mysql php5-gd php5-mcrypt php5-intl

RUN apt-get update \
    && apt-get install -y $PHP_DEPS curl git vim cron supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN rm /etc/php5/fpm/php.ini && ln -sf /etc/php5/cli/php.ini /etc/php5/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = Europe\/Moscow/" /etc/php5/cli/php.ini
RUN sed -i "s/upload_max_filesize =.*/upload_max_filesize = 100M/" /etc/php5/cli/php.ini
RUN sed -i "s/post_max_size =.*/post_max_size = 100M/" /etc/php5/cli/php.ini
RUN sed -i "s/memory_limit =.*/memory_limit = 128M/" /etc/php5/cli/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/cli/php.ini
COPY supervisord.conf /etc/supervisor/
COPY services.conf /etc/supervisor/conf.d/
COPY www.conf /etc/php5/fpm/pool.d/

RUN groupadd -r -g 2000 web \
  && useradd -r -m -u 2000 -g web web

RUN curl -LsS https://getcomposer.org/composer.phar -o /usr/local/bin/composer.phar \
    && chmod +x /usr/local/bin/composer.phar \
    && curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony \
    && chmod a+x /usr/local/bin/symfony

WORKDIR /home/web
EXPOSE 9000
ENTRYPOINT ["/usr/bin/supervisord", "-n"]