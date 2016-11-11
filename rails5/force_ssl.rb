# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

uncomment_lines 'config/environments/production.rb', 'config.force_ssl = true'
git_commit 'Enable force_ssl'
