# -*- coding: utf-8 -*-
# remotipart for rails 3.1 or later
#
# usage:
#  rake rails:template LOCATION=path/to/remotipart.rb

gem 'remotipart'
gsub_file 'app/assets/javascripts/application.js', %r"(?<=//= require jquery_ujs\n)(?!.*remotipart)"m do
  <<-JS
//= require jquery.remotipart
  JS
end
