FROM alpine:3.4

MAINTAINER Domingo Kiser domingo.kiser@gmail.com

RUN echo "create salt user and directories" \
    && addgroup salt \
    && adduser -S -G salt salt \
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

ENV SALT_VERSION 2016.3.1
ENV LOG_LEVEL error

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk --update upgrade && apk add --no-cache runit curl python py-msgpack py-yaml py-jinja2 py-pip \
    py-requests py-zmq py-crypto py-m2crypto py-openssl libzmq py-cryptography py-cffi py-psutil && \
    pip install GitPython croniter salt==$SALT_VERSION

# Volumes
VOLUME ["/home/salt", "/etc/salt", "/etc/salt/pki", "/var/cache/salt", "/var/log/salt", "/etc/salt/master.d", "/srv/salt"]

# Expose ports for salt
EXPOSE 4505
EXPOSE 4506

# Run as non privileged user
USER salt

# Launch supervisor (lets us run syndic in future if we need to expand)
COPY run.sh /usr/bin/run.sh
ENTRYPOINT ["/usr/bin/run.sh"]
