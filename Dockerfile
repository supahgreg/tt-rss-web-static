FROM registry.fakecake.org/docker.io/nginxinc/nginx-unprivileged:1-alpine

ADD public /usr/share/nginx/html
COPY redirects.conf /etc/nginx/conf.d/
