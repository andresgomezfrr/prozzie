FROM alpine:latest

RUN apk add --no-cache gettext
COPY binary-gen/k2http/k2http /app/
COPY config.yaml /app/config.yaml_env
COPY k2http-start.sh /app/
COPY topics-config.sh /app/
WORKDIR /app
ENTRYPOINT ["sh", "-c", "./k2http-start.sh"]

