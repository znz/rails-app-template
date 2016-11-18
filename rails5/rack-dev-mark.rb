# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

gem_bundle 'rack-dev-mark' do
  create_file 'config/locales/rack_dev_mark.ja.yml', <<-'YAML'.b
ja:
  rack_dev_mark:
    development: '開発版'
    staging: 'ステージング'
  YAML

  inject_into_class 'config/application.rb', 'Application', <<-'RUBY'
    # Customize themes if you want to do so
    config.rack_dev_mark.theme = [
      :title,
      Rack::DevMark::Theme::GithubForkRibbon.new(position: 'left-bottom', color: 'black'),
    ]

  RUBY

  append_file '.env.development', <<-'ENV'.b
RACK_DEV_MARK_ENV=development
  ENV
end
