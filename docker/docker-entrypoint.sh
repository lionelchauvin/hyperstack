#!/bin/bash

bundle check || bundle install --binstubs="$BUNDLE_BIN"

# create database if needed
mysqlshow -uroot | grep $MYSQL_TEST_DATABASE &> /dev/null || rake spec:prepare

# update chromedriver in order to make it compatible with container's chromium
current_chromedriver_version=`bundle exec chromedriver --version`
if ! [[ $current_chromedriver_version =~ $CHROMEDRIVER_VERSION ]]; then
  echo "update chromedriver"
  bundle exec chromedriver-update $CHROMEDRIVER_VERSION
fi

exec "$@"
