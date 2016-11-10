# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

create_file 'app.json', <<-'JSON'
{
  "scripts": {
    "dokku": {
      "predeploy": "bundle exec rake db:migrate"
    }
  }
}
JSON

# copy from default Procfile
create_file 'Procfile', <<-'PROCFILE'
console: bin/rails console
rake: bundle exec rake
web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec rake jobs:work
PROCFILE

create_file 'CHECKS', <<-'CHECKS'
ATTEMPTS=20
/robots.txt  the robots.txt file
CHECKS

git_commit 'Add dokku related files'
