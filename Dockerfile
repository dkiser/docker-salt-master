# CentOS 7 Docker image for Salt Master with Multi-Master PKI

FROM centos:centos7

MAINTAINER Domingo Kiser domingo.kiser@gmail.com

RUN echo "create salt user and directories" \
    && groupadd -r salt \
    && useradd  -r -g salt salt \
    && mkdir -p \
      /etc/salt/pki \
      /var/cache/salt \
      /srv/salt \
      /var/log/salt \
      /etc/salt/master.d \
      /var/run/salt \
      /home/salt \
    && chown -R salt:salt \
      /etc/salt \
      /var/cache/salt \
      /srv/salt \
      /var/log/salt \
      /var/run/salt \
      /home/salt

ENV SALT_VERSION 2015.5.3
ENV LOG_LEVEL error

# Yum updates and installs
RUN yum install -y epel-release
RUN yum update -y && yum install -y \
  python \
  python-devel \
  python-pip \
  gcc \
  swig \
  gcc \
  openssl-devel \
  zeromq3-devel \
  supervisor \
  openssh-clients \
  git

# Install everything salt needs via PIP
ENV SWIG_FEATURES "-cpperraswarn -includeall -I/usr/include/openssl"
RUN pip install \
  M2Crypto \
  pyzmq \
  PyYAML \
  pycrypto \
  msgpack-python \
  jinja2 \
  psutil \
  requests \
  GitPython \
  croniter \
  supervisor-stdout \
  salt==$SALT_VERSION

# Volumes
VOLUME ["/home/salt", "/etc/salt", "/etc/salt/pki", "/var/cache/salt", "/var/log/salt", "/etc/salt/master.d", "/srv/salt"]

# Supervisor configuration
ADD config/supervisord.conf /etc/supervisor/supervisord.conf
ADD config/supervisor-salt.conf /etc/supervisor/conf.d/salt.conf
# don't run supervisord as root but as our salt user
RUN touch /var/log/supervisord.log && chown salt:salt /var/log/supervisord.log
RUN touch /var/run/supervisord.pid && chown salt:salt /var/run/supervisord.pid

# Expose ports for salt
EXPOSE 4505
EXPOSE 4506

# Run as non privileged user
USER salt

# Launch supervisor (lets us run syndic in future if we need to expand)
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
