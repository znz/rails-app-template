# -*- coding: utf-8 -*-

get "https://raw.github.com/rmm5t/jquery-timeago/master/jquery.timeago.js", "vendor/assets/javascripts/jquery.timeago.js"
get "https://raw.github.com/rmm5t/jquery-timeago/master/locales/jquery.timeago.ja.js", "vendor/assets/javascripts/jquery.timeago.ja.js"

# with jquery-mobile
if File.directory?("app/assets/javascripts/mobile")
  create_file "app/assets/javascripts/mobile/jquery-timeago.js.coffee", <<-COFFEE
#= require jquery.timeago
#= require jquery.timeago.ja
jquery_timeago = ->
  jQuery(".timeago").timeago()

$(document).on "pageshow", (event, ui) ->
  jquery_timeago()
  COFFEE
end
