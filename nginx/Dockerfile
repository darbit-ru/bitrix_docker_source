FROM nginx:1.20.2

LABEL org.opencontainers.image.source="https://github.com/bitrixdock/bitrixdock"

RUN apt-get update \
    && apt-get -y install cron \
    && apt-get -y install certbot \
    && apt-get -y install python3-certbot-nginx \
    &&

ADD conf/nginx.conf /etc/nginx/
COPY conf/conf.d/ /etc/nginx/conf.d/
COPY letsencrypt/ /etc/letsencrypt/

COPY cron/cronjob /etc/cron.d/cronjob
RUN chmod 0644 /etc/cron.d/cronjob
RUN crontab /etc/cron.d/cronjob
RUN touch /var/log/cron.log
CMD cron

RUN usermod -u 1000 www-data

STOPSIGNAL SIGTERM

CMD ["nginx"]

EXPOSE 80 443
