#!/usr/bin/env bash
set -euo pipefail

# Default values for script options
OLS_VERSION=''
PHP_VERSION=''
PUSH=false
TAG=''
BUILDER='imbios'
REPO='openlitespeed'
CONFIG=''
EPACE='        '

# Function to print styled messages
echow() {
  local FLAG=$1
  shift
  echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}

# Display help message and exit
help_message() {
  echo -e "\033[1mOPTIONS\033[0m"
  echow '-O, --ols [VERSION] -P, --php [lsphpVERSION]'
  echo "${EPACE}${EPACE}Example: bash build.sh --ols 1.7.11 --php lsphp80"
  echow '--push'
  echo "${EPACE}${EPACE}Example: build.sh --ols 1.7.11 --php lsphp80 --push, will push to Docker Hub"
  echow '--tag [TAG]'
  echo "${EPACE}${EPACE}Set a custom tag for the image."
  exit 0
}

# Check if input is empty and display help message
check_input() {
  if [ -z "${1:-}" ]; then
    help_message
  fi
}

# Build the Docker image
build_image() {
  local version=$1
  local php_version=$2
  local dockerfile=$3
  local suffix=$4

  echo "Building image ${BUILDER}/${REPO}:${version}-${php_version}${suffix} using ${dockerfile}..."
  docker build -f "${dockerfile}" . \
    --tag "${BUILDER}/${REPO}:${version}-${php_version}${suffix}" \
    --build-arg OLS_VERSION="${version}" \
    --build-arg PHP_VERSION="${php_version}"
}

# Test the Docker image
test_image() {
  local version=$1
  local php_version=$2
  local suffix=$3

  local id
  id=$(docker run -d "${BUILDER}/${REPO}:${version}-${php_version}${suffix}")

  docker exec -i "${id}" bash -c '
    mkdir -p /var/www/vhosts/localhost/html/ &&
    echo "<?php phpinfo();" > /var/www/vhosts/localhost/html/index.php &&
    /usr/local/lsws/bin/lswsctrl restart
  '

  sleep 5

  local http_status https_status
  http_status=$(docker exec -i "${id}" curl -s -o /dev/null -Ik -w "%{http_code}" http://localhost)
  https_status=$(docker exec -i "${id}" curl -s -o /dev/null -Ik -w "%{http_code}" https://localhost)

  docker kill "${id}"

  if [[ "${http_status}" != "200" || "${https_status}" != "200" ]]; then
    echo '[X] Test failed!'
    echo "http://localhost returned ${http_status}"
    echo "https://localhost returned ${https_status}"
    exit 1
  else
    echo '[O] Tests passed!'
  fi
}

# Push the Docker image to the repository
push_image() {
  local version=$1
  local php_version=$2
  local tag=$3
  local suffix=$4

  if [ "${PUSH}" = true ]; then
    [ -f ~/.docker/litespeedtech/config.json ] && CONFIG="--config ~/.docker/litespeedtech"

    echo "Pushing image ${BUILDER}/${REPO}:${version}-${php_version}${suffix}..."
    docker ${CONFIG} push "${BUILDER}/${REPO}:${version}-${php_version}${suffix}"

    if [ -n "${tag}" ]; then
      docker tag "${BUILDER}/${REPO}:${version}-${php_version}${suffix}" "${BUILDER}/${REPO}:${tag}"
      docker ${CONFIG} push "${BUILDER}/${REPO}:${tag}"
    fi
  else
    echo 'Skip Push.'
  fi
}

# Main function to handle the build/test/push flow
main() {
  build_image "${OLS_VERSION}" "${PHP_VERSION}" "Dockerfile" ""
  test_image "${OLS_VERSION}" "${PHP_VERSION}" ""
  push_image "${OLS_VERSION}" "${PHP_VERSION}" "${TAG}" ""

  # Build, test, and push Dockerfile.pear variant
  build_image "${OLS_VERSION}" "${PHP_VERSION}" "Dockerfile.pear" "-pear"
  test_image "${OLS_VERSION}" "${PHP_VERSION}" "-pear"
  push_image "${OLS_VERSION}" "${PHP_VERSION}" "${TAG}" "-pear"
}

# Parse command-line arguments
while [ $# -gt 0 ]; do
  case "$1" in
  -[hH] | --help)
    help_message
    ;;
  -[oO] | --ols)
    shift
    check_input "$1"
    OLS_VERSION="$1"
    ;;
  -[pP] | --php)
    shift
    check_input "$1"
    PHP_VERSION="$1"
    ;;
  -[tT] | --tag)
    shift
    TAG="$1"
    ;;
  --push)
    PUSH=true
    ;;
  *)
    help_message
    ;;
  esac
  shift
done

check_input "${OLS_VERSION}"
check_input "${PHP_VERSION}"

# Start the build process
main
