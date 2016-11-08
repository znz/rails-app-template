# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

gem_bundle 'omniauth' do
  gem 'omniauth-facebook'
  gem 'omniauth-github'
  gem 'omniauth-google-oauth2'
  gem 'omniauth-twitter'
  # use update instead of install to resolve incompatible json version
  # see https://github.com/arunagw/omniauth-twitter/pull/108
  bundle_update
end

create_file '.env.development', <<-'ENV'
FACEBOOK_KEY=dummy
FACEBOOK_SECRET=dummy
GITHUB_CONSUMER_KEY=dummy
GITHUB_CONSUMER_SECRET=dummy
GOOGLE_CLIENT_ID=dummy
GOOGLE_CLIENT_SECRET=dummy
TWITTER_CONSUMER_KEY=dummy
TWITTER_CONSUMER_SECRET=dummy
ENV

gsub_file 'app/models/user.rb', /^  devise :confirmable, :lockable, :timeoutable,\n/, "  devise :confirmable, :lockable, :timeoutable, :omniauthable,\n"

# if call `config.omniauth`, do not have to set `omniauth_providers` to `User` model
insert_into_file 'config/initializers/devise.rb', <<-'RUBY', after: /^  # config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'\n/
  $OmniAuthProviders = {}
  $OmniAuthProviders[:facebook] = {
    name: 'Facebook',
    icon: :facebook,
  }
  key, secret = ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
  if key && secret
    config.omniauth :facebook, key, secret
  end
  $OmniAuthProviders[:github] = {
    name: 'GitHub',
    icon: :github,
  }
  key, secret = ENV['GITHUB_CONSUMER_KEY'], ENV['GITHUB_CONSUMER_SECRET']
  if key && secret
    config.omniauth :github, key, secret
  end
  $OmniAuthProviders[:google_oauth2] = {
    name: 'Google',
    icon: :google,
  }
  key, secret = ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET']
  if key && secret
    config.omniauth :google_oauth2, key, secret
  end
  $OmniAuthProviders[:twitter] = {
    name: 'Twitter',
    icon: :twitter,
  }
  key, secret = ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  if key && secret
    config.omniauth :twitter, key, secret
  end
RUBY

git_commit 'Setup omniauth'

gsub_file 'app/views/devise/shared/_links.html.slim', <<-'SLIM', <<-'SLIM'
    = link_to t('.sign_in_with_provider', provider: provider.to_s.titleize), omniauth_authorize_path(resource_name, provider)
SLIM
    = link_to icon($OmniAuthProviders[provider][:icon])+t('.sign_in_with_provider', provider: $OmniAuthProviders[provider][:name]), omniauth_authorize_path(resource_name, provider)
SLIM
insert_into_file 'app/controllers/application_controller.rb', <<-'RUBY', after: /^  include QueryParamsHelper\n/
  include Devise::OmniAuth::UrlHelpers
RUBY
git_commit 'Update OmniAuth view'
