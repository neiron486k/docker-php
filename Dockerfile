FROM ubuntu
MAINTAINER Alexey Astafev "efsneiron@gmail.com"

ENV PHP_DEPS php7.0-cli php7.0-curl php7.0-fpm php7.0-mysql php7.0-gd php7.0-mcrypt php7.0-intl php7.0-xml php7.0-zip
ENV INI_CONF=/etc/php/7.0
ENV NOTVISIBLE "in users profile"

RUN apt-get update \
	&& apt-get install -y $PHP_DEPS openssh-server supervisor git \
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
RUN php -r "unlink('composer-setup.php');"

COPY www.conf $INI_CONF/fpm/pool.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 9000 22

CMD ["/usr/bin/supervisord"]