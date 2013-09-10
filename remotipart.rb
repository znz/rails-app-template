# -*- coding: utf-8 -*-
# remotipart for rails 3.1 or later
#
# usage:
#  rake rails:template LOCATION=path/to/remotipart.rb

gem 'remotipart'
insert_into_file 'app/assets/javascripts/application.js', "//= require jquery.remotipart\n", after: "//= require jquery_ujs\n"
