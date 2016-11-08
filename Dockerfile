# Base Image / OS
FROM phusion/baseimage
MAINTAINER perkris <chris.krisdan@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

# Set correct environment variables
ENV HOME /root

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# INstall Language pack required by PHP 5.6
RUN apt-get update && \
    apt-get install -y language-pack-en-base

ENV LC_ALL=en_GB.UTF-8
ENV LANG=en_GB.UTF-8

# Add PPA for PHP 5.6
RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository ppa:ondrej/php


### ************  INSTALL PHP *********** ###

# Install PHP 5.6
RUN DEBIAN_FRONTEND=noninteractive LC_ALL=en_US.UTF-8 \
    apt-get update && apt-get install -y \
    php5.6 php5.6-mbstring php5.6-mcrypt php5.6-mysql php5.6-xml php5.6-curl php5.6-cli php5.6-gd php5.6-intl php5.6-xsl
    

### ***********  INSTALL DRUPAL 7.51 ********** ###
RUN mkdir /var/www/drupal/
ADD drupal/ /var/www/drupal/
ADD localDrupal-config.conf /etc/apache2/sites-available/drupal7-test.conf


### ***********  INSTALL APACHE ********** ###


# Install Apache
RUN apt-get install -qy apache2 apache2-utils libapache2-mod-php php-curl
#RUN service apache2 start

# Update apache configuration with this one
#ADD apache-config.conf /etc/apache2/sites-available/000-default.conf
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

RUN a2ensite drupal7-test
RUN service apache2 restart

# Enable PHP
RUN a2enmod php5.6

# USE PORT 8080
EXPOSE 8080

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
