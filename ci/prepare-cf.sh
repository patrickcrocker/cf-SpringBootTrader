#!/bin/bash
#
# All CF_* variables are provided externally from this script

set -e

if [ "true" = "$CF_SKIP_SSL" ]; then
  cf api $CF_API_URL --skip-ssl-validation
else
  cf api $CF_API_URL
fi

# Login to CF

cf auth $CF_USERNAME $CF_PASSWORD

UUID=$(uuidgen)

# Use temp org if none specified
if [ -z "$CF_ORG" ]; then
  CF_ORG="pivotal-bank-$UUID"
fi

HAS_ORG=$(cf orgs | grep $CF_ORG || true)
if [ -z "$HAS_ORG" ]; then
  cf create-org $CF_ORG
fi

cf target -o $CF_ORG

# Use temp space if none specified
if [ -z "$CF_SPACE" ]; then
  CF_SPACE="pivotal-bank-$UUID"
fi

HAS_SPACE=$(cf spaces | grep $CF_SPACE || true)
if [ -z "$HAS_SPACE" ]; then
  cf create-space $CF_SPACE
fi

cf target -s $CF_SPACE

SLEEP=0

HAS_SERVICE=$(cf services | grep traderdb || true)
if [ -z "$HAS_SERVICE" ]; then
  cf create-service $CF_DB_SERVICE
fi

HAS_SERVICE=$(cf services | grep config-server || true)
if [ -z "$HAS_SERVICE" ]; then
  cf create-service p-config-server standard config-server -c "{ \"git\": { \"uri\": \"$CF_CONFIG_SERVER_URI\", \"label\": \"$CF_CONFIG_SERVER_LABEL\" } }"
  SLEEP=60
fi

HAS_SERVICE=$(cf services | grep discovery-service || true)
if [ -z "$HAS_SERVICE" ]; then
  cf create-service p-service-registry standard discovery-service
  SLEEP=70
fi

HAS_SERVICE=$(cf services | grep circuit-breaker-dashboard || true)
if [ -z "$HAS_SERVICE" ]; then
  cf create-service p-circuit-breaker-dashboard standard circuit-breaker-dashboard
  SLEEP=110
fi

# give services time to spin up
echo "waiting for services to initialize ($SLEEP seconds)"
sleep $SLEEP
