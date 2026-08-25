#!/bin/bash

set -e

chown -R redis:redis /var/log/redis

exec redis-server /usr/local/etc/redis/redis.conf
