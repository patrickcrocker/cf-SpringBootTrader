#!/bin/bash
# Uses shyaml from https://github.com/0k/shyaml

CONFIG_FILE=~/.concourse/pivotal-bank.yml
CONCOURSE_TARGET=lite

export CF_API_URL=$(cat $CONFIG_FILE | shyaml get-value cf-api-url)
export CF_USERNAME=$(cat $CONFIG_FILE | shyaml get-value cf-username)
export CF_PASSWORD=$(cat $CONFIG_FILE | shyaml get-value cf-password)
export CF_SKIP_SSL=$(cat $CONFIG_FILE | shyaml get-value cf-skip-ssl)
export CF_ORG=$(cat $CONFIG_FILE | shyaml get-value cf-org)
export CF_SPACE=$(cat $CONFIG_FILE | shyaml get-value cf-space)
export CF_APP_NAME=$(cat $CONFIG_FILE | shyaml get-value cf-accounts-service-name)
export CF_CONFIG_SERVER_URI=$(cat $CONFIG_FILE | shyaml get-value cf-config-server-uri)
export CF_CONFIG_SERVER_LABEL=$(cat $CONFIG_FILE | shyaml get-value cf-config-server-label)
export CF_DB_SERVICE=$(cat $CONFIG_FILE | shyaml get-value cf-db-service)

fly -t $CONCOURSE_TARGET execute -c itest.yml -i accounts-milestone=../build/libs -i accounts-service=../
