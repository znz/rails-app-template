# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

gem_bundle 'jquery-ui-rails'
create_file 'app/assets/javascripts/autocomplete.coffee', <<-'COFFEE'
#= require jquery-ui/widgets/autocomplete
jQuery ($) ->
  set_handlers = ->
    $('input.autocomplete').each ->
      $this = $(this)
      source = []
      $this.closest('.form-group').find('datalist.autocomplete option').each (i,e) -> source.push(e.value)
      $this.autocomplete
        source: source
        autoFocus: true
        delay: 0
        minLength: 0
      .on 'focus', ->
        $this.autocomplete('search', '')
  $(document).on 'turbolinks:load', set_handlers
COFFEE

create_file 'app/assets/stylesheets/autocomplete.scss', <<-'SCSS'
//= require jquery-ui/autocomplete

.ui-autocomplete {
  max-height: 200px;
  overflow-y: auto;
  overflow-x: hidden;
}
SCSS

git_commit 'Enable jquery-ui/autocomplete'
