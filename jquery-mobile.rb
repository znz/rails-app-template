# -*- coding: utf-8 -*-
unless /jquery_mobile_rails/ =~ File.read('Gemfile')
  gem 'jquery_mobile_rails'
  abort('run again after `bundle install`')
end

create_file 'app/assets/stylesheets/mobile.css', <<-CSS
/*
 *= require_self
 *= require jquery.mobile
 *= require_tree ./mobile
 */
.notice {
    background-color: #DFF0D8;
    border-color: #D6E9C6;
    color: #468847;
    border-radius: 4px 4px 4px 4px;
    padding: 15px;
}
.alert {
    background-color: #F2DEDE;
    border-color: #EED3D7;
    color: #B94A48;
    border-radius: 4px 4px 4px 4px;
    padding: 15px;
}
CSS
create_file 'app/assets/stylesheets/mobile/.keep'

create_file 'app/assets/javascripts/mobile.js', <<-JS
//= require jquery
//= require jquery_ujs
//= require_tree ./mobile
//= require jquery.mobile
JS
create_file 'app/assets/javascripts/mobile/.keep'
create_file 'app/assets/javascripts/mobile/jqm_ja.js.coffee', <<-COFFEE
$(document).on "mobileinit", ->
  $.mobile.loader.prototype.options.text = "読み込み中です..."
  $.mobile.loader.prototype.options.textVisible = false
  $.mobile.pageLoadErrorMessage = "読み込みに失敗しました。"
  $.mobile.page.prototype.options.backBtnText = "戻る"
  $.mobile.listview.prototype.options.filterPlaceholder = "検索..."
  $.mobile.table.prototype.options.columnBtnText = "列の増減..."
  $.mobile.dialog.prototype.options.closeBtnText =
    $.mobile.selectmenu.prototype.options.closeText = "閉じる"
  $.mobile.collapsible.prototype.options.expandCueText = "クリックで開く"
  $.mobile.collapsible.prototype.options.collapseCueText = "クリックで閉じる"
$(document).on "pageloadfailed", (event, data) ->
  if data.xhr.status == 401
    window.location.href = data.absUrl
COFFEE

create_file 'app/views/layouts/mobile.html.haml', <<-HAML
!!! 5
%html
  %head
    %meta(charset="utf-8")
    %meta(http-equiv="X-UA-Compatible" content="IE=edge,chrome=1")
    %meta(name="viewport" content="width=device-width, initial-scale=1")
    %meta(name="format-detection" content="telephone=no")
    = csrf_meta_tags
    %title= content_for?(:title) ? yield(:title) : @title
    = stylesheet_link_tag "mobile", media: "all"
    = javascript_include_tag "mobile"
  %body
    %div(data-role="page" data-theme="b" data-url="\#{request.original_url}")
      - if content_for?(:header)
        %div(data-role="header")
          = yield :header
      - elsif content_for?(:title)
        %div(data-role="header")
          %h1= yield :title
      %div(data-role="content")
        - if notice
          %p.notice= notice
        - if alert
          %p.alert= alert
        = yield
      - if content_for?(:footer)
        %div(data-role="footer")
          = yield :footer
HAML
