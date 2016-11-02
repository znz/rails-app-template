#!/bin/sh
set -eux
RAILS_ROOT=$(pwd)
cd "$(dirname $0)"
TEMPLATE_DIR=$(pwd)
cd "$RAILS_ROOT"
bundle exec rake rails:template "LOCATION=$TEMPLATE_DIR/generators.rb" || :
bundle exec rake rails:template "LOCATION=$TEMPLATE_DIR/slim-rails.rb" || :
bundle exec rake rails:template "LOCATION=$TEMPLATE_DIR/heroku.rb" || :
bundle exec rake rails:template "LOCATION=$TEMPLATE_DIR/rspec.rb" || :
bundle exec rake rails:template "LOCATION=$TEMPLATE_DIR/secret_token.rb" || :
