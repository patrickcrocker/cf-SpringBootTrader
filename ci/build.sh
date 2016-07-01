#!/bin/bash

set -e

VERSION=`cat version/number`

pushd project
  ./gradlew -PversionNumber=$VERSION clean assemble
popd

cp project/build/libs/$ARTIFACT_ID-$VERSION.jar build-output/.
