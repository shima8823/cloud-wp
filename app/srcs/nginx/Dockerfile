FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y nginx openssl gettext-base --no-install-recommends &&\
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /var/www/html -s /sbin/nologin nginx

RUN mkdir -p /var/www/html /run/nginx /etc/nginx/ssl && \
    chown -R nginx:nginx /var/www/html /run/nginx /etc/nginx/ssl

COPY ./conf/nginx.conf /etc/nginx/
COPY ./conf/default.conf /etc/nginx/conf.d/default.conf.template
COPY ./tools/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80 443
ENTRYPOINT ["docker-entrypoint.sh"]
