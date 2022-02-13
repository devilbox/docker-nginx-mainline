#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
DOCKER_NAME="${1}"
ARCH="${2}"


###
### Load Library
###
# shellcheck disable=SC1090
. ${CWD}/.lib.sh



###
### Preparation
###
RAND_DIR="$( mktemp -d )"
RAND_NAME1="$( get_random_name )"
RAND_NAME2="$( get_random_name )"
run "chmod 0755 ${RAND_DIR}"
run "echo \"<?php echo 'hello world php';\" > ${RAND_DIR}/index.php"


###
### Startup container
###
run "docker run -d --rm --platform ${ARCH} \
 -v ${RAND_DIR}:/var/www/default/htdocs \
 --name ${RAND_NAME1} devilbox/php-fpm-8.1"

run "docker run -d --rm --platform ${ARCH} \
 -v ${RAND_DIR}:/var/www/default/htdocs \
 -p 127.0.0.1:80:80 \
 -e DEBUG_ENTRYPOINT=2 \
 -e DEBUG_RUNTIME=1 \
 -e NEW_UID=$( id -u ) \
 -e NEW_GID=$( id -g ) \
 -e PHP_FPM_ENABLE=1 \
 -e PHP_FPM_SERVER_ADDR=${RAND_NAME1} \
 -e PHP_FPM_SERVER_PORT=9000 \
 --link ${RAND_NAME1} \
 --name ${RAND_NAME2} ${DOCKER_NAME}"


###
### Tests
###
run "sleep 20"  # Startup-time is longer on cross-platform
run "docker ps"
run "docker logs ${RAND_NAME1}"
run "docker logs ${RAND_NAME2}"
run "curl localhost"
run "curl localhost | grep 'hello world php'"


###
### Cleanup
###
run "docker stop ${RAND_NAME1}"
run "docker stop ${RAND_NAME2}"