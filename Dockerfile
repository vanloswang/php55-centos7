FROM centos:centos7

MAINTAINER symantec_paas <xuan_tang@symantec.com>

LABEL io.openshift.s2i.scripts-url=image:///usr/local/sti

LABEL io.k8s.description="Platform for building and running PHP 5.5 applications" \
      io.k8s.display-name="Apache 2.4 with PHP 5.5" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,php,php55."

ENV HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sti:$PATH


# Basic dependencies; Setup default user for the build execution and for
# application runtime execution.
RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
  yum install -y --setopt=tsflags=nodocs \
  autoconf \
  automake \
  bsdtar \
  epel-release \
  findutils \
  gcc-c++ \
  gdb \
  gettext \
  git \
  libcurl-devel \
  libxml2-devel \
  libxslt-devel \
  lsof \
  make \
  openssl-devel \
  patch \
  procps-ng \
  wget \
  yum-utils \
  yum clean all -y && \
  mkdir -p ${HOME} && \
  useradd -u 1001 -r -g 0 -d ${HOME} -s /sbin/nologin \
      -c "Default Application User" default && \
  chown -R 1001:0 /opt/app-root 

ADD entrypoint/container-entrypoint /usr/bin/container-entrypoint

WORKDIR ${HOME}
ENTRYPOINT ["container-entrypoint"]


# PHP specific
RUN yum install -y \
    httpd \
    php \
    php-mysqlnd \
    php-pgsql \
    php-bcmath \
    php-devel \
    php-fpm \
    php-gd \
    php-intl \
    php-ldap \
    php-mbstring \
    php-pdo \
    php-pecl-memcache \
    php-process \
    php-soap \
    php-opcache \
    php-xml \
    php-pecl-imagick \
    php-pecl-xdebug && \
    yum clean all -y

COPY ./.s2i/bin /usr/local/sti
COPY ./contrib/ /opt/app-root/

RUN sed -i -f /opt/app-root/etc/httpdconf.sed /etc/httpd/conf/httpd.conf && \
    sed -i '/php_value session.save_path/d' /etc/httpd/conf.d/php.conf && \
    head -n151 /etc/httpd/conf/httpd.conf | tail -n1 | grep "AllowOverride All" || exit && \
    mkdir /tmp/sessions && \
    chmod -R 777 /etc && \
    chmod -R 777 /var/run/httpd && \
    chmod -R 777 /tmp/sessions && \
    chown -R 1001:0 /opt/app-root /tmp/sessions

USER 1001
EXPOSE 8080

CMD ["usage"] 
