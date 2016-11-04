#!/bin/bash
#
# All CF_* variables are provided externally from this script

set -e -x

source $(dirname $0)/common.sh

login $CF_API_URL $CF_USERNAME $CF_PASSWORD $CF_SKIP_SSL

target_org $CF_ORG

target_space $CF_SPACE

cf delete accounts-service -f -r
cf delete portfolio-service -f -r
cf delete quotes-service -f -r
cf delete web-ui -f -r

cf delete-service traderdb -f
cf delete-service config-server -f
cf delete-service discovery-service -f
cf delete-service circuit-breaker-dashboard -f
