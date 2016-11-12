# Base Image / OS
FROM phusion/baseimage
MAINTAINER perkris <chris.krisdan@gmail.com>

# Meta-Data
LABEL version="1.0.0" type="Drupal Host"

# Set correct environment variables
ENV DEBIAN_FRONTEND=noninteractive \
	HOME=/root \
	LC_ALL=en_GB.UTF-8 \
	LANG=en_GB.UTF-8

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# INstall Language pack required by PHP 5.6, Add PPA for PHP 5.6
RUN apt-get update && \
    apt-get install -y language-pack-en-base \
    software-properties-common && \
    add-apt-repository ppa:ondrej/php


### ************  INSTALL PHP *********** ###

# Install PHP 5.6
RUN apt-get update && apt-get install -y \
    php5.6 \
    php5.6-mbstring \
    php5.6-mcrypt \
    php5.6-mysql \
    php5.6-xml \
    php5.6-curl \
    php5.6-cli \
    php5.6-gd \
    php5.6-intl \
    php5.6-xsl

### ***********  INSTALL APACHE ********** ###


# Install Apache
RUN apt-get install -qy \
	apache2 \
	apache2-utils \
	libapache2-mod-php \
	php-curl


# Update apache configuration with this one
ADD drupal7-config.conf /etc/apache2/sites-available/drupal7-test.conf
ADD apache-ports.conf /etc/apache2/ports.conf
RUN echo "ServerName localhost" > /etc/apache2/conf-available/fqdn.conf

# Manually set the apache environment variables in order to get apache to work immediately.
RUN echo www-data > /etc/container_environment/APACHE_RUN_USER
RUN echo www-data > /etc/container_environment/APACHE_RUN_GROUP
RUN echo /var/log/apache2 > /etc/container_environment/APACHE_LOG_DIR
RUN echo /var/lock/apache2 > /etc/container_environment/APACHE_LOCK_DIR
RUN echo /var/run/apache2.pid > /etc/container_environment/APACHE_PID_FILE

### Add Shell Script for starting Apache2:
RUN mkdir /etc/service/apache2
ADD apache.sh /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run
RUN a2enconf fqdn
RUN service apache2 start

### ***********  INSTALL DRUPAL 7.51 ********** ###
RUN mkdir /var/www/drupal/
ADD drupal/ /var/www/drupal/
#COPY drupal/sites/default/default.settings.php /var/www/drupal/sites/default/settings.php
#RUN find /var/www/drupal/ -type d -exec chmod u=rwx,g=rx,o= '{}' \;
#RUN find /var/www/drupal/ -type f -exec chmod u=rw,g=r,o= '{}' \;
#RUN chmod 774 /var/www/drupal/sites/default/
#RUN chmod 774 /var/www/drupal/sites/default/settings.php
#RUN chown 

RUN a2ensite drupal7-test
RUN service apache2 restart

# Enable PHP
RUN a2enmod php5.6

# USE PORT 8080
EXPOSE 8080

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
