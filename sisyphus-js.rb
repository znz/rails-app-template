# -*- coding: utf-8 -*-
# http://sisyphus-js.herokuapp.com says "Sisyphus is released under MIT License"
#
# this app-template is minimal usage of sisyphus.js.
# If you want to use with more utilities,
# you consider to use sisyphus-rails gem.
# (but the gem may include old sisyphus.js.)

get "https://raw.github.com/simsalabim/sisyphus/master/sisyphus.js", "vendor/assets/javascripts/sisyphus.js"
get "https://raw.github.com/andris9/jStorage/master/jstorage.js", "vendor/assets/javascripts/jstorage.js"

# with jquery-mobile
if File.directory?("app/assets/javascripts/mobile")
  # excludeFields from sisyphus-rails gem
  create_file "app/assets/javascripts/mobile/sisyphus-jqm.js.coffee", <<-COFFEE
#= require jstorage
#= require sisyphus
$(document).on "pageshow", (event, ui) ->
  $('form').sisyphus({excludeFields: $('input[name=utf8], input[name=_method], input[name=authenticity_token]')})
# save again when post failed
$(document).on "pageloadfailed", (event, data) ->
  $('form').sisyphus().saveAllData()
  COFFEE
end
