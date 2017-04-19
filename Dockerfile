FROM ubuntu:16.04
MAINTAINER Alexey Astafev "efsneiron@gmail.com"

## Gosu installation
ENV GOSU_VERSION 1.9
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove ca-certificates wget

ENV PHP_DEPS php7.1-cli php7.1-curl php7.1-fpm php7.1-mysql php7.1-gd php7.1-mcrypt php7.1-intl php7.1-xml php7.1-zip php7.1-mbstring php7.1-sqlite3
ENV INI_CONF=/etc/php/7.1
ENV NOTVISIBLE "in users profile"

RUN apt-get update \
   && apt-get install -y software-properties-common locales \
   && locale-gen en_US.utf8 \
   && export LANG=en_US.utf8 \
   && add-apt-repository ppa:ondrej/php -y \
   && apt-get update \
   && apt-get install -y $PHP_DEPS openssh-server supervisor cifs-utils nfs-common curl git \
   && rm -rf /var/lib/apt/lists/*


RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN echo "export VISIBLE=now" >> /etc/profile
RUN rm $INI_CONF/fpm/php.ini && ln -s $INI_CONF/cli/php.ini $INI_CONF/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = Europe\/Moscow/" $INI_CONF/cli/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" $INI_CONF/cli/php.ini
RUN mkdir -p /run/php
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/local/bin
RUN mv /usr/local/bin/composer.phar /usr/local/bin/composer
RUN php -r "unlink('composer-setup.php');"
RUN wget https://phar.phpunit.de/phpunit.phar
RUN chmod +x phpunit.phar
RUN mv phpunit.phar /usr/local/bin/phpunit
RUN curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony
RUN chmod a+x /usr/local/bin/symfony

COPY entrypoint.sh /usr/local/bin/
COPY www.conf $INI_CONF/fpm/pool.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000 22

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]