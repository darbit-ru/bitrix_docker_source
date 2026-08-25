#!/bin/bash

set -e

WORKDIR=/opt/push-server
SERVICE_CONFIG=push-server-multi
PUB_TMPL=push-server-pub-__PORT__.json
SUB_TMPL=push-server-sub-__PORT__.json

[[ -z "$PUSHROLE" ]] && PUSHROLE="all"

SECURITY_KEY="${PUSH_SERVER_KEY}"

pushd "$WORKDIR" >/dev/null || exit 1

[[ ! -f /etc/default/$SERVICE_CONFIG ]] && \
    cp -fv etc/sysconfig/${SERVICE_CONFIG} /etc/default/${SERVICE_CONFIG}

if [[ $(grep -v "^$\|^#" /etc/default/${SERVICE_CONFIG} | grep -c "SECURITY_KEY") -eq 0 ]]; then
    echo "SECURITY_KEY=${SECURITY_KEY}" >> /etc/default/${SERVICE_CONFIG}
fi

if [[ $(grep -v "^$\|^#" /etc/default/${SERVICE_CONFIG} | grep -c "RUN_DIR") -eq 0 ]]; then
    echo "RUN_DIR=/tmp/push-server" >> /etc/default/${SERVICE_CONFIG}
fi
if [[ $(grep -v "^$\|^#" /etc/default/${SERVICE_CONFIG} | grep -c "REDIS_SOCK") -eq 0 ]]; then
    echo "REDIS_SOCK=${REDIS_SOCK:-redis:6379}" >> /etc/default/${SERVICE_CONFIG}
fi
if [[ $(grep -v "^$\|^#" /etc/default/${SERVICE_CONFIG} | grep -c "WS_HOST") -eq 0 ]]; then
    echo "WS_HOST=${WS_HOST:-0.0.0.0}" >> /etc/default/${SERVICE_CONFIG}
fi

[[ ! -d /tmp/push-server ]] && mkdir /tmp/push-server

sed -i "s/^USER=.*/USER=root/" /etc/default/${SERVICE_CONFIG}
sed -i "s/^GROUP=.*/GROUP=root/" /etc/default/${SERVICE_CONFIG}

[[ ! -d /etc/sysconfig ]] && mkdir /etc/sysconfig
ln -sf /etc/default/${SERVICE_CONFIG} /etc/sysconfig

if [[ "$PUSHROLE" == "sub" ]]; then
    sed -i "s/ID_SUB=[0-9]\+/ID_SUB=0/" /etc/default/push-server-multi
elif [[ "$PUSHROLE" == "pub" ]]; then
    sed -i "s/ID_PUB=[0-9]\+/ID_PUB=0/" /etc/default/push-server-multi
fi

[[ ! -d /etc/push-server ]] && mkdir /etc/push-server

if [[ ! -f /etc/push-server/$PUB_TMPL ]]; then
    cp -fv etc/push-server/$PUB_TMPL /etc/push-server/
fi
if [[ ! -f /etc/push-server/$SUB_TMPL ]]; then
    cp -fv etc/push-server/$SUB_TMPL /etc/push-server/
fi

cp -fv etc/init.d/push-server-multi /usr/local/bin
chmod 755 /usr/local/bin/push-server-multi

if [[ ( "$PUSHROLE" == "all" || "$PUSHROLE" == "sub" ) && \
    ! -f /etc/push-server/push-server-sub-8010.json ]]; then
    /usr/local/bin/push-server-multi configs "$PUSHROLE"
elif [[ "$PUSHROLE" == "pub" && \
    ! -f /etc/push-server/push-server-pub-9010.json ]]; then
    /usr/local/bin/push-server-multi configs "$PUSHROLE"
fi

rm -rf /etc/push-server/$PUB_TMPL
rm -rf /etc/push-server/$SUB_TMPL

/usr/local/bin/push-server-multi systemd_start "$PUSHROLE"

. /etc/default/${SERVICE_CONFIG}

while sleep 120; do
    if [[ "$PUSHROLE" == "pub" || "$PUSHROLE" == "all" ]]; then
        for n in $(seq 0 "$ID_PUB"); do
            port="901${n}"
            pidf=/tmp/push-server/pub-${port}.pid
            pidn=$(cat "$pidf")
            if ! ps ax -o pid | grep "^\s*${pidn}$" >/dev/null 2>&1; then
                echo "One of the processes [pub-${port}] has already exited."
                echo "Pid File: $pidf $(cat "$pidf")"
                exit 1
            fi
        done
    fi

    if [[ "$PUSHROLE" == "sub" || "$PUSHROLE" == "all" ]]; then
        for n in $(seq 0 "$ID_SUB"); do
            port="801${n}"
            pidf=/tmp/push-server/sub-${port}.pid
            pidn=$(cat "$pidf")
            if ! ps ax -o pid | grep "^\s*${pidn}$" >/dev/null 2>&1; then
                echo "One of the processes [sub-${port}] has already exited."
                echo "Pid file: $pidf $(cat "$pidf")"
                exit 1
            fi
        done
    fi
done

popd >/dev/null 2>&1
