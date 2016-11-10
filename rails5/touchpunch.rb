# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

gem_bundle 'touchpunch-rails' do
  create_file 'app/assets/javascripts/touchpunch.coffee', <<-'COFFEE'
#= require jquery.ui.touch-punch
  COFFEE
end
