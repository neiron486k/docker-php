FROM debian:jessie
MAINTAINER Alexey Astafev "efsneiron@gmail.com"

ENV PHP_DEPS php7.0-cli php7.0-curl php7.0-fpm php7.0-mysql php7.0-gd php7.0-mcrypt php7.0-intl php7.0-xml php7.0-zip php7.0-mbstring php7.0-sqlite3
ENV INI_CONF=/etc/php/7.0
ENV NOTVISIBLE "in users profile"
ENV GOSU_VERSION 1.9

RUN apt-get update \
    && apt-get install -y wget \
    && echo "deb http://packages.dotdeb.org jessie all" > /etc/apt/sources.list.d/dotdeb.list \
    && echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.list \
    && wget https://www.dotdeb.org/dotdeb.gpg \
    && apt-key add dotdeb.gpg \
    && apt-get update \
    && apt-get install -y $PHP_DEPS openssh-server supervisor cifs-utils nfs-common curl \
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
RUN dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

COPY entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh

COPY www.conf $INI_CONF/fpm/pool.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 9000 22

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]