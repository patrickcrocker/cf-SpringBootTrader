#!/bin/bash
#
# All CF_* variables are provided externally from this script

set -e

SERVICE_PROVISION_TIMEOUT=${SERVICE_PROVISION_TIMEOUT:-500}

function wait_for_service_instance() {
  service_instance=$1

  guid=`cf service ${service_instance} --guid`

  start=`date +%s`
  while true; do
    # Get the service instance info in JSON from CC and parse out the async 'state'
    state=`cf curl /v2/service_instances/${guid} | jq -r .entity.last_operation.state`

    if [ "$state" == "succeeded" ]; then
      echo "Service ${service_instance} is ready"
      return
    elif [ "$state" == "failed" ]; then
      echo "Service ${service_instance} failed to provision"
      cf delete-service -f $service_instance
      exit 1
    fi

    now=`date +%s`
    time=$(($now - $start))
    if [[ "$time" -ge "$SERVICE_PROVISION_TIMEOUT" ]]; then
      echo "Timed out waiting for service instance to provision: ${service_instance}"
      cf delete-service -f $service_instance
      exit 1
    fi
    sleep 5
  done
}

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
  wait_for_service_instance config-server
fi

HAS_SERVICE=$(cf services | grep discovery-service || true)
if [ -z "$HAS_SERVICE" ]; then
  cf create-service p-service-registry standard discovery-service
  wait_for_service_instance discovery-service
fi

HAS_SERVICE=$(cf services | grep circuit-breaker-dashboard || true)
if [ -z "$HAS_SERVICE" ]; then
  cf create-service p-circuit-breaker-dashboard standard circuit-breaker-dashboard
  wait_for_service_instance circuit-breaker-dashboard
fi

# give services time to spin up
echo "waiting for services to initialize ($SLEEP seconds)"
sleep $SLEEP
