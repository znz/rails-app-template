# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

gem_bundle 'touchpunch-rails' do
  create_file 'app/assets/javascripts/touchpunch.coffee', <<-'COFFEE'
#= require jquery.ui.touch-punch
  COFFEE
end
create_file 'app/assets/javascripts/jquery-ui/mouse.js', <<-JAVASCRIPT
//= require jquery-ui/widgets/mouse
JAVASCRIPT
git_commit 'Add workaround file for touchpunch-rails 1.0.3'
