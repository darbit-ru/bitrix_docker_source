FROM darbit/bitrix-push-server:v2.0

WORKDIR /opt/push-server

EXPOSE 9099

COPY push_config.toml .

ENV CONFIG_FILE=/opt/push-server/push_config.toml

CMD ["push-server"]