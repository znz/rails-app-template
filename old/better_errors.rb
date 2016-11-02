# -*- coding: utf-8 -*-

# when gems already added, gem_group add group block without gem lines
unless /better_errors/ =~ File.read('Gemfile')
  gem_group :development do
    gem "better_errors"
    gem "binding_of_caller"
  end
end
