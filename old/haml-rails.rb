# -*- coding: utf-8 -*-
gem 'haml'
# 'haml-rails' includes generators only,
# thus use it in development only
gem 'haml-rails', group: :development
initializer 'haml.rb', <<-'RUBY'
Haml::Template.options[:attr_wrapper] = '"'
RUBY
