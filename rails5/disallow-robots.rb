# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

uncomment_lines 'public/robots.txt', /(User-agent|Disallow):/
git_commit 'Disallow from robots'
