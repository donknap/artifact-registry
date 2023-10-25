FROM registry:latest

RUN echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.15/main" > /etc/apk/repositories && \
    echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.15/community" >> /etc/apk/repositories

RUN apk add --update --no-cache nginx apache2-utils git openssl
RUN mkdir -p /etc/nginx/http.d/

ENV NGINX_PROXY_HEADER_Host '$http_host'
ENV NGINX_LISTEN_PORT '80'
ENV SHOW_CATALOG_NB_TAGS 'false'

ENV SINGLE_REGISTRY true
ENV REGISTRY_TITLE 'Docker Registry UI'
ENV DELETE_IMAGES true
ENV SHOW_CONTENT_DIGEST true
ENV NGINX_PROXY_PASS_URL 'http://127.0.0.1:5000'
ENV SHOW_CATALOG_NB_TAGS true
ENV CATALOG_MIN_BRANCHES 1
ENV CATALOG_MAX_BRANCHES 1
ENV TAGLIST_PAGE_SIZE 100
ENV REGISTRY_SECURED false
ENV CATALOG_ELEMENTS_LIMIT 1000

ENV REGISTRY_USERNAME admin
ENV REGISTRY_PASSWORD 123456

ENV ENABLE_PUBLIC_PULL 1

###ENV REGISTRY_STORAGE_DELETE_ENABLED true

ENV WEB_PATH /home/
WORKDIR $WEB_PATH
ADD ./start.sh /home/start.sh
ADD ./auth-server /home/auth-server
ADD ./config-auth-server.yml /home/config-auth-server.yml
###ADD ./config-registry.yml /home/config-registry.yml
ADD ./root-certificate.pem /home/root-certificate.pem
ADD ./root-key.pem /home/root-key.pem
ADD ./nginx/default.conf /etc/nginx/http.d/default.conf

RUN git clone  https://ghproxy.com/https://github.com/Joxit/docker-registry-ui /home/source-ui

RUN mkdir -p /etc/nginx/conf.d && cp /home/source-ui/nginx/default.conf /etc/nginx/conf.d/default.conf
RUN cp -r /home/source-ui/dist/ /usr/share/nginx/html/
RUN cp /home/source-ui/favicon.ico /usr/share/nginx/html/
RUN mkdir -p /docker-entrypoint.d && cp /home/source-ui/bin/90-docker-registry-ui.sh /docker-entrypoint.d/90-docker-registry-ui.sh
RUN rm -rf /home/source-ui

CMD ["sh", "/home/start.sh"]