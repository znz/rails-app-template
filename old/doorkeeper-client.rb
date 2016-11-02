# -*- coding: utf-8 -*-
unless /devise/ =~ File.read('Gemfile')
  gem 'devise'
  gem 'omniauth'
  gem 'omniauth-oauth2'
  abort('run again after `bundle install`')
end

initializer = 'config/initializers/devise.rb'
#remove_file initializer
generate 'devise:install'
gsub_file 'config/routes.rb', /^\s*devise_for :users( do\n[\s\S]*?^  end)?\n/ do
  <<-RUBY
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  devise_scope :user do
    get 'sign_in',  to: 'devise/sessions#new',     as: :new_user_session
    get 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end
  RUBY
end

def secrets(key)
  if Rails.application.respond_to?(:secrets)
    append_file "config/secrets.yml" do
      "  #{key}: <%= ENV[\"#{key.upcase}\"] %>\n"
    end
    "Rails.application.secrets.#{key}"
  else
    "ENV['#{key.upcase}'] || (require 'secure_token'; secure_token('#{key}'))"
  end
end

# tokens
if File.exist?('lib/secure_token.rb') || File.exist?('config/secrets.yml')
  gsub_file initializer, /config\.secret_key = .*/ do
    "config.secret_key = #{secrets('devise_secret_key')}"
  end
  gsub_file initializer, /config\.pepper = .*/ do
    "config.pepper = #{secrets('devise_pepper')}"
  end
end
# OmniAuth
create_file 'lib/omniauth/strategies/doorkeeper.rb', <<-RUBY
module OmniAuth
  module Strategies
    class Doorkeeper < OmniAuth::Strategies::OAuth2
      option :name, :doorkeeper

      option :client_options, {
        site: #{secrets('doorkeeper_site')} || 'http://localhost:3000',
        authorize_path: #{secrets('doorkeeper_authorize_path')} || '/users/oauth/authorize',
      }

      uid { raw_info['id'] }

      info do
        {
          email: raw_info['email'],
          name: raw_info['name'],
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/api/v1/me.json').parsed || {}
      end
    end
  end
end
RUBY
insert_into_file initializer, <<-RUBY, after: /\# config\.omniauth .*\n/
  require Rails.root+'lib/omniauth/strategies/doorkeeper'
  config.omniauth :doorkeeper, #{secrets('doorkeeper_app_id')}, #{secrets('doorkeeper_app_secret')}
RUBY
# auto logout
uncomment_lines initializer, /config\.(timeout_in|expire_auth_token_on_timeout) =/
gsub_file initializer, /config\.timeout_in = \d+\.minutes/ do
  # default: 30.minutes
  'config.timeout_in = 1.minutes if Rails.env.development?'
end
gsub_file initializer, /config\.expire_auth_token_on_timeout = false/ do
  'config.expire_auth_token_on_timeout = true'
end

generate 'devise User'
devise_create_user = 'db/migrate/1000_devise_create_users.rb'
f, = Dir['db/migrate/*_devise_create_users.rb']
if f != devise_create_user
  FileUtils::Verbose.mv f, devise_create_user
end
f, = Dir['db/migrate/*_add_devise_to_users.rb']
if f && File.exist?(f)
  remove_file f
end
devise_create_user = 'db/migrate/1000_devise_create_users.rb'
comment_lines devise_create_user, /:(encrypted_password|reset_password_|remember_created_at)/
create_file 'db/migrate/2000_add_omniauth_columns_to_users.rb', <<-RUBY
class AddOmniauthColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :name, :string
  end
end
RUBY

create_file 'app/controllers/concerns/auth_doorkeeper.rb', <<-RUBY
module AuthDoorkeeper
  private

  def auto_authenticate_omniauth_user!
    return if current_user
    session[:user_return_to] = request.original_url
    redirect_to main_app.user_omniauth_authorize_path(:doorkeeper)
  end
end
RUBY

create_file 'app/controllers/concerns/doorkeeper_api_v1.rb', <<-RUBY
module DoorkeeperApiV1
  private

  def access_token
    return @access_token if defined?(@access_token)
    config = Devise.omniauth_configs[:doorkeeper]
    strategy = config.strategy_class.new(*config.args)
    token = session[:doorkeeper_token]
    @access_token = OAuth2::AccessToken.new(strategy.client, token)
  end

  def get_me
    access_token.get("/api/v1/me.json").parsed
  end

  def get_posts
    access_token.get("/api/v1/posts.json").parsed
  end

  def create_post(title, body)
    access_token.post("/api/v1/posts", params: { post: { title: title, body: body } }).status == 200
  end
end
RUBY

insert_into_file 'app/controllers/application_controller.rb', <<-RUBY, after: /ActionController::Base\n/
  include AuthDoorkeeper
  before_filter :auto_authenticate_omniauth_user!

RUBY

create_file 'app/controllers/users/omniauth_callbacks_controller.rb', <<-RUBY
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  protect_from_forgery except: :doorkeeper # https://github.com/plataformatec/devise/issues/2432
  skip_filter :auto_authenticate_omniauth_user!, only: :doorkeeper

  def doorkeeper
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.find_for_doorkeeper_oauth(request.env['omniauth.auth'], current_user)
    session[:doorkeeper_token] = request.env["omniauth.auth"]["credentials"]["token"]

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication #this will throw if @user is not activated
      if is_navigational_format?
        set_flash_message(:notice, :success, kind: ENV['DOORKEEPER_SITE_NAME'] || 'Doorkeeper')
      end
    else
      session['devise.doorkeeper_data'] = request.env['omniauth.auth']
      if respond_to?(:new_user_registration_url)
        redirect_to new_user_registration_url
      else
        redirect_to root_url
      end
    end
  end

  def after_omniauth_failure_path_for(scope)
    if respond_to?(:new_session_path)
      new_session_path(scope)
    else
      root_path
    end
  end
end
RUBY

create_file 'app/models/concerns/find_for_doorkeeper_oauth.rb', <<-RUBY
module FindForDoorkeeperOauth
  extend ActiveSupport::Concern

  module ClassMethods
    def find_for_doorkeeper_oauth(auth, signed_in_resource=nil)
      uid = auth.uid.to_s
      id = uid.to_i
      user = self.where(provider: auth.provider, uid: uid).first
      if user
        user.name = auth.info.name
        user.email = auth.info.email
        user.save! if user.changed?
      else
        user = self.create!({
          id: id, # use same id
          name: auth.info.name,
          provider: auth.provider,
          uid: uid,
          email: auth.info.email,
          #password: Devise.friendly_token[0,20]
        })
      end
      user
    end
  end
end
RUBY

create_file 'app/models/user.rb', <<-RUBY
class User < ActiveRecord::Base
  devise :timeoutable
  devise :omniauthable, omniauth_providers: [:doorkeeper]
  include FindForDoorkeeperOauth
end
RUBY

if File.exist?('spec/support')
  create_file 'spec/support/devise.rb', <<-RUBY
RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
end
  RUBY
end

if File.exist?('spec/factories')
  create_file 'spec/factories/users.rb', <<-'RUBY'
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    sequence(:name)  { |n| "user #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
  end
end
  RUBY
end

Dir.glob('spec/controllers/*_controller_spec.rb') do |path|
  case path
  when %r!\Aspec/controllers/(.+)s_controller_spec\.rb\z!
    #model_name = $1
    insert_into_file path, <<-RUBY, after: /^describe .*Controller do\n/
  before (:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
  end
    RUBY
  end
end
