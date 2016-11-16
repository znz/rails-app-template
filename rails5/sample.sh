#!/bin/bash
set -euxo pipefail
TARGET=/tmp/sample
export RBENV_VERSION=2.3.2
export TEST_MODE=1
cd $(dirname "$0")
TEMPLATE_DIR=$(pwd)
cd /tmp
rm -rf "$TARGET"
rails new "$TARGET" -BT -m "$TEMPLATE_DIR/template.rb"
cd "$TARGET"
rails app:template LOCATION="$TEMPLATE_DIR/dokku.rb"
rails app:template LOCATION="$TEMPLATE_DIR/disallow-robots.rb"
rails app:template LOCATION="$TEMPLATE_DIR/carrierwave.rb"
rails app:template LOCATION="$TEMPLATE_DIR/text_to_html.rb"
rails app:template LOCATION="$TEMPLATE_DIR/autogrow.rb"
rails app:template LOCATION="$TEMPLATE_DIR/autocomplete.rb"
rails app:template LOCATION="$TEMPLATE_DIR/users.rb"
rails app:template LOCATION="$TEMPLATE_DIR/omniauth.rb"
rails app:template LOCATION="$TEMPLATE_DIR/touchpunch.rb"
rails app:template LOCATION="$TEMPLATE_DIR/navbar.rb"
rake db:setup
git gc
