FROM nginx:1.20.2

LABEL org.opencontainers.image.source="https://github.com/bitrixdock/bitrixdock"

COPY conf/nginx.conf /etc/nginx/
COPY conf/conf.d/ /etc/nginx/conf.d/

RUN usermod -u 1000 www-data

CMD ["nginx"]

EXPOSE 80 443
