# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

gsub_file 'config/environments/production.rb', <<-'RUBY', <<-'RUBY'
  # config.force_ssl = true
RUBY
  config.force_ssl = ENV['NO_FORCE_SSL'].blank?
RUBY
git_commit 'Enable force_ssl unless NO_FORCE_SSL set'
