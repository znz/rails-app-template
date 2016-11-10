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

git_commit 'Add dokku related files'
