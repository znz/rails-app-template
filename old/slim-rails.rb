# -*- coding: utf-8 -*-
gem 'slim-rails'
initializer 'slim.rb', <<-'RUBY'
# use html instead of xhtml
Slim::Engine.set_default_options format: :html
if Rails.env.development?
#  Slim::Engine.set_default_options pretty: true
end
RUBY
