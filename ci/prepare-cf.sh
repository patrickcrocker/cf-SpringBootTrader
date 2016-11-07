#!/bin/bash
#
# All CF_* variables are provided externally from this script

set -e

CF_SERVICE_PROVISION_TIMEOUT=${CF_SERVICE_PROVISION_TIMEOUT:-500}

source $(dirname $0)/common.sh

login $CF_API_URL $CF_USERNAME $CF_PASSWORD $CF_SKIP_SSL

create=true
UUID=$(uuidgen)

# Use temp org if none specified
if [ -z "$CF_ORG" ]; then
  CF_ORG="pivotal-bank-$UUID"
fi

target_org $CF_ORG $create

# Use temp space if none specified
if [ -z "$CF_SPACE" ]; then
  CF_SPACE="pivotal-bank-$UUID"
fi

target_space $CF_SPACE $create

# Create Services
if ! service_exists traderdb; then
  cf create-service $CF_DB_SERVICE
fi

if ! service_exists config-server; then
  cf create-service p-config-server standard config-server -c "{ \"git\": { \"uri\": \"$CF_CONFIG_SERVER_URI\", \"label\": \"$CF_CONFIG_SERVER_LABEL\" } }"
  wait_for_service_instance config-server $CF_SERVICE_PROVISION_TIMEOUT
fi

if ! service_exists discovery-service; then
  cf create-service p-service-registry standard discovery-service
  wait_for_service_instance discovery-service $CF_SERVICE_PROVISION_TIMEOUT
fi

if ! service_exists circuit-breaker-dashboard; then
  cf create-service p-circuit-breaker-dashboard standard circuit-breaker-dashboard
  wait_for_service_instance circuit-breaker-dashboard $CF_SERVICE_PROVISION_TIMEOUT
fi
