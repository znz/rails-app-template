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
sisyphus_form = ->
  $('form[method="post"]').sisyphus({excludeFields: $('input[name=utf8], input[name=_method], input[name=authenticity_token]')})
$(document).on "pageshow", (event, ui) ->
  sisyphus_form()
$(document).on "pageloadfailed", (event, data) ->
  sisyphus_form().saveAllData()
  COFFEE
end
