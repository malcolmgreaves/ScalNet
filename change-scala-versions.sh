#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This shell script is adapted from Apache Flink (in turn, adapted from Apache Spark) some modifications.

set -e

VALID_VERSIONS=( 2.10 2.11 2.12 )

usage() {
  echo "Usage: $(basename $0) [-h|--help] <scala version to be used>
where :
  -h| --help Display this help text
  valid scala version values : ${VALID_VERSIONS[*]}
" 1>&2
  exit 1
}

if [[ ($# -ne 1) || ( $1 == "--help") ||  $1 == "-h" ]]; then
  usage
fi

TO_BINARY=$1

check_scala_version() {
  for i in ${VALID_VERSIONS[*]}; do [ $i = "$1" ] && return 0; done
  echo "Invalid Scala version: $1. Valid versions: ${VALID_VERSIONS[*]}" 1>&2
  exit 1
}

check_scala_version "$TO_BINARY"

FROM_BINARY=$(awk -F '[<>]' '/artifactId/{print $3}' pom.xml | grep scalnet | cut -d '_' -f 2)
FROM_BINARY_VERSION=scala${FROM_BINARY//.}.version
FROM_VERSION=$(grep -F -m 1 "$FROM_BINARY_VERSION" pom.xml); FROM_VERSION="${FROM_VERSION#*>}"; FROM_VERSION="${FROM_VERSION%<*}";
FROM_VERSION=$(echo $FROM_VERSION | perl -pe 's/.*?([0-9]+\.[0-9]+\.[0-9]+).*/\1/g')

TO_BINARY_VERSION=scala${TO_BINARY//.}.version
TO_VERSION=$(grep -F -m 1 "$TO_BINARY_VERSION" pom.xml); TO_VERSION="${TO_VERSION#*>}"; TO_VERSION="${TO_VERSION%<*}";
TO_VERSION=$(echo $TO_VERSION | perl -pe 's/.*?([0-9]+\.[0-9]+\.[0-9]+).*/\1/g')

FROM_BINARY=_$FROM_BINARY
TO_BINARY=_$TO_BINARY

echo "$FROM_BINARY"
echo "$TO_BINARY"

sed_i() {
  sed -e "$1" "$2" > "$2.tmp" && mv "$2.tmp" "$2"
}

export -f sed_i

echo "Updating Scala versions in pom.xml files to Scala $1, from $FROM_VERSION to $TO_VERSION";

BASEDIR=$(dirname $0)

#Artifact ids, ending with "_2.10" or "_2.11". Spark, spark-mllib, kafka, etc.
find "$BASEDIR" -name 'pom.xml' -not -path '*target*' \
  -exec bash -c "sed_i 's/\(artifactId>.*\)'$FROM_BINARY'<\/artifactId>/\1'$TO_BINARY'<\/artifactId>/g' {}" \;

#Scala versions, like <scala.version>2.10</scala.version>
find "$BASEDIR" -name 'pom.xml' -not -path '*target*' \
  -exec bash -c "sed_i 's/\(scala.version>\)'$FROM_VERSION'<\/scala.version>/\1'$TO_VERSION'<\/scala.version>/g' {}" \;

#Scala binary versions, like <scala.binary.version>2.10</scala.binary.version>
find "$BASEDIR" -name 'pom.xml' -not -path '*target*' \
  -exec bash -c "sed_i 's/\(scala.binary.version>\)'${FROM_BINARY#_}'<\/scala.binary.version>/\1'${TO_BINARY#_}'<\/scala.binary.version>/g' {}" \;

#Scala versions, like <artifactId>scala-library</artifactId> <version>2.10.6</version>
find "$BASEDIR" -name 'pom.xml' -not -path '*target*' \
  -exec bash -c "sed_i 's/\(version>\)'$FROM_VERSION'<\/version>/\1'$TO_VERSION'<\/version>/g' {}" \;

#Scala maven plugin, <scalaVersion>2.10</scalaVersion>
find "$BASEDIR" -name 'pom.xml' -not -path '*target*' \
  -exec bash -c "sed_i 's/\(scalaVersion>\)'$FROM_VERSION'<\/scalaVersion>/\1'$TO_VERSION'<\/scalaVersion>/g' {}" \;

echo "Done updating Scala versions.";
