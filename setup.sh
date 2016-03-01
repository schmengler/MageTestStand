#!/bin/bash
set -e
set -x
 

function cleanup {
  if [ -z $SKIP_CLEANUP ]; then
    echo "Removing build directory ${BUILDENV}"
    rm -rf "${BUILDENV}"
  fi
}
 
trap cleanup EXIT

# check if this is a travis environment
if [ ! -z $TRAVIS_BUILD_DIR ] ; then
  WORKSPACE=$TRAVIS_BUILD_DIR
fi

if [ -z $WORKSPACE ] ; then
  echo "No workspace configured, please set your WORKSPACE environment"
  exit
fi
 
BUILDENV=`mktemp -d /tmp/mageteststand.XXXXXXXX`
 
echo "Using build directory ${BUILDENV}"
 
git clone https://github.com/schmengler/MageTestStand.git "${BUILDENV}"
cp -rf "${WORKSPACE}" "${BUILDENV}/.modman/"
# if module came with own dependencies that were installed, use these:
if [ -d "${WORKSPACE}/vendor" ] ; then
  cp -f ${WORKSPACE}/composer.lock "${BUILDENV}/"
  cp -rf ${WORKSPACE}/vendor "${BUILDENV}/"
fi
if [ -d "${WORKSPACE}/.modman" ] ; then
  cp -rf ${WORKSPACE}/.modman/* "${BUILDENV}/.modman/"
fi
${BUILDENV}/install.sh
 
cd ${BUILDENV}/htdocs
if [ ! -z $CODECLIMATE_REPO_TOKEN ] ; then
  ${BUILDENV}/vendor/bin/phpunit --colors -d display_errors=1 --coverage-clover ${BUILDENV}/clover.xml --coverage-text
  cd ${BUILDENV}/.modman/`basename ${WORKSPACE}`
  composer require codeclimate/php-test-reporter --dev
  vendor/bin/test-reporter --coverage-report=${BUILDENV}/clover.xml
else
  ${BUILDENV}/vendor/bin/phpunit --colors -d display_errors=1
fi

