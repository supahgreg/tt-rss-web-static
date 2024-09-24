FROM registry.fakecake.org/docker.io/python:3.9-alpine AS build

WORKDIR /app

ADD requirements.txt /app

RUN pip3 install -r requirements.txt

ADD docs /app/docs
ADD mkdocs.yml /app/
ADD overrides /app/overrides

RUN mkdocs build --strict

FROM registry.fakecake.org/docker.io/nginxinc/nginx-unprivileged:1-alpine

COPY --from=build /app/html /usr/share/nginx/html
