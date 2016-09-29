#! /bin/bash

# The Docker App Container's development entrypoint.
# This is a script used by the project's Docker development environment to
# setup the app containers and databases upon runnning.
set -e

# 5: Check or install the app dependencies via Bundler:
bundle check || bundle install --jobs 8 --retry 5

bundle exec rake db:create db:migrate db:test:prepare
exec "$@"
