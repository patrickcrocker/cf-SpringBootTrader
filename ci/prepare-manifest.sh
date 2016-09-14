#!/bin/bash
#
# All CF_* variables are provided externally from this script

set -e

# copy the artifact to the task-output folder
cp release/$CF_ARTIFACT_ID-*.jar prepare-manifest-output/.

pushd prepare-manifest-output

ARTIFACT_PATH=$(ls $CF_ARTIFACT_ID-*.jar)

cat <<EOF >manifest.yml
---
applications:
- name: $CF_APP_NAME
  host: $CF_APP_HOST
  path: $ARTIFACT_PATH
  memory: 512M
  instances: 1
  timeout: 180
  services: [ $CF_APP_SERVICES ]
  env:
    SPRING_PROFILES_ACTIVE: cloud
    JAVA_OPTS: -Djava.security.egd=file:///dev/urandom
    JBP_CONFIG_OPEN_JDK_JRE: '[memory_calculator: { memory_sizes: { metaspace: 100m }, memory_heuristics: {metaspace: 10, heap: 65, native: 20, permgen: 10, stack: 5}  }]'
EOF

if [ "true" = "$CF_SKIP_SSL" ]; then
  echo "    CF_TARGET: $CF_API_URL" >> manifest.yml
fi

popd
