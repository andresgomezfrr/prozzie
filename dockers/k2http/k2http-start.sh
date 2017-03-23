#/bin/sh

APP_DIR=/app
cd $APP_DIR
export KAFKA_TOPICS_ENV=$(./topics-config.sh)
envsubst < config.yaml_env > config.yaml
./k2http --config config.yaml
