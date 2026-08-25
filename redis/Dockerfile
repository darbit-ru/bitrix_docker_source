FROM redis:8.2

VOLUME /var/log/redis

RUN mkdir -p /usr/local/etc/redis

ADD conf/redis.conf /usr/local/etc/redis/redis.conf
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chown root:redis /usr/local/etc/redis/redis.conf && \
    chmod 0755 /usr/local/bin/docker-entrypoint.sh

EXPOSE 6379

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
