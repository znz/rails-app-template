# -*- coding: utf-8 -*-
unless /pundit/ =~ File.read('Gemfile')
  gem 'pundit'
  abort('run again after `bundle install`')
end

insert_into_file 'app/controllers/application_controller.rb', <<-RUBY, after: /class ApplicationController.*\n/
  include Pundit
RUBY

generate 'pundit:install'
