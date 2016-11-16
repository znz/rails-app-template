# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

create_file 'app/assets/stylesheets/nav.scss', <<-'SCSS'
.navbar-brand {
  padding-top: 8px;
  img {
    height: 34px;
    width: 34px;
    display: inline;
  }
}

a.dropdown-toggle {
  cursor: pointer;
}

#main {
  margin-top: 80px;
}
SCSS

create_file 'app/helpers/link_to_devise_helper.rb', <<-'RUBY'
# -*- coding: utf-8 -*-
# frozen_string_literal: true
module LinkToDeviseHelper
  def link_to_sign_in_or_out(html_options={})
    if user_signed_in?
      body = icon(:'sign-out') + t(:"devise.shared.links.sign_out", default: "Sign out")
      html_options = { method: :delete }.merge(html_options)
      link_to body, destroy_user_session_path, html_options if respond_to?(:destroy_user_session_path)
    else
      body = icon(:'sign-in') + t(:"devise.shared.links.sign_in", default: "Sign in")
      link_to body, new_user_session_path, html_options if respond_to?(:new_user_session_path)
    end
  end
end
RUBY

create_file 'app/views/layouts/_navbar.html.slim', <<-'SLIM'
a.sr-only(href="#main")= t(:'nav.skip_to_main', default: 'Skip to main content')

nav.navbar.navbar-inverse.navbar-fixed-top role="navigation"
  .container-fluid
    .navbar-header
      button.navbar-toggle.collapsed type="button" data-toggle="collapse" data-target=".navbar-collapse"
        span.sr-only= t(:'nav.toggle_navigation', default: 'Toggle navigation')
        span.icon-bar
        span.icon-bar
        span.icon-bar
      = link_to '/', class: 'navbar-brand', data: { turbolinks: false } do
        = t(:'nav.brand')
    .collapse.navbar-collapse
      ul.nav.navbar-nav.navbar-right
        - if user_signed_in?
          = render partial: 'shared/listing'
        - if link = link_to_sign_in_or_out
          li= link
SLIM

create_file 'app/views/shared/_listing.html.slim', <<-'SLIM'
li.dropdown
  a.dropdown-toggle data-toggle="dropdown" onclick=";"
    = icon(:sitemap)+t("helpers.titles.index", models: "")
    b.caret
  ul.dropdown-menu
    - I18n.t("activerecord.models").each do |key, body|
      - klass = key.to_s.classify.constantize
      - next unless respond_to? "#{ActiveModel::Naming.route_key(klass)}_path"
      - next unless can? :read, klass
      li= link_to icon(:folder)+t("helpers.titles.index", default: "Listing %{models}", models: body.pluralize), klass
SLIM

insert_into_file 'app/views/layouts/application.html.slim', <<-'SLIM', before: /^    \.container\#main role="main"/
    = render partial: 'layouts/navbar'
SLIM

create_file 'config/locales/nav.ja.yml', <<-'YAML'
ja:
  nav:
    brand: "サンプルシステム"
    skip_to_main: "本文までスキップ"
    toggle_navigation: "ナビゲーションをトグル"
  devise:
    shared:
      links:
        sign_in: "ログイン"
        sign_out: "ログアウト"
YAML

git_commit 'Add navbar'
