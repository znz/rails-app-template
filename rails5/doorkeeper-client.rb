# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

gem_bundle 'omniauth' do
  gem 'omniauth-oauth2'
  bundle_install
end

create_file '.env.development', <<-'ENV'
DOORKEEPER_APP_ID=dummy
DOORKEEPER_APP_SECRET=dummy
DOORKEEPER_SITE=http://localhost:3000/
DOORKEEPER_SITE_NAME=Example
ENV

gsub_file 'app/models/user.rb', /^  devise :confirmable, :lockable, :timeoutable,\n         :database_authenticatable, :registerable,\n         :recoverable, :rememberable, :trackable, :validatable\n/, "  devise :timeoutable, :omniauthable, :trackable\n"

insert_into_file 'config/initializers/devise.rb', <<-'RUBY', after: /^  # config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'\n/
  require Rails.root+'lib/omniauth/strategies/doorkeeper'
  config.omniauth :doorkeeper, ENV['DOORKEEPER_APP_ID'], ENV['DOORKEEPER_APP_SECRET'], { scope: 'public write' }
RUBY

create_file 'lib/omniauth/strategies/doorkeeper.rb', <<-'RUBY'
module OmniAuth
  module Strategies
    class Doorkeeper < OmniAuth::Strategies::OAuth2
      option :name, :doorkeeper

      option :client_options, {
        :site => ENV['DOORKEEPER_SITE'] || 'http://localhost:3000',
        :authorize_path => '/users/oauth/authorize'
      }

      uid { raw_info['id'] }

      info do
        {
          email: raw_info['email'],
          name: raw_info['name'],
        }
      end

      def callback_url
        full_host + script_name + callback_path
      end

      def raw_info
        @raw_info ||= access_token.get('/api/v1/me.json').parsed || {}
      end
    end
  end
end
RUBY

create_file 'app/controllers/users/omniauth_callbacks_controller.rb', <<-'RUBY'
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  protect_from_forgery except: :doorkeeper # https://github.com/plataformatec/devise/issues/2432
  skip_before_action :auto_authenticate_omniauth_user!, only: :doorkeeper

  def doorkeeper
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.find_for_doorkeeper_oauth(request.env['omniauth.auth'], current_user)
    session[:doorkeeper_token] = request.env["omniauth.auth"]["credentials"]["token"]

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      if is_navigational_format?
        # hide flash message after auto sign in
        #set_flash_message(:notice, :success, kind: ENV['DOORKEEPER_SITE_NAME'] || 'Doorkeeper')
        flash.delete(:notice)
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

if ENV['USE_SAME_ID']
  use_same_id = <<-'RUBY'
        attributes[:id] = id # use same id
  RUBY
end
if ENV['ADD_ADMIN_ROLE_TO_FIRST_USER']
  add_admin_role = <<-'RUBY'
        if self.count == 1
          # add admin role to first user
          user.add_role(:admin)
        end
  RUBY
end
create_file 'app/models/concerns/find_for_doorkeeper_oauth.rb', <<-"RUBY"
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
        attributes = {
          name: auth.info.name,
          provider: auth.provider,
          uid: uid,
          email: auth.info.email,
        }
#{use_same_id}\
        if user.respond_to?(:password)
          attributes[:password] = Devise.friendly_token[0,20]
        end
        user = self.create!(attributes)
#{add_admin_role}\
      end
      user
    end
  end
end
RUBY

inject_into_class 'app/models/user.rb', 'User', <<-'RUBY'
  include FindForDoorkeeperOauth
RUBY

gsub_file 'config/routes.rb', %q(devise_for :users, path_prefix: 'auth', path_names: { sign_in: 'login', sign_out: 'logout' }), %q(devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }, path_prefix: 'auth', path_names: { sign_in: 'login', sign_out: 'logout' })

inject_into_class 'app/controllers/application_controller.rb', 'ApplicationController', <<-'RUBY'
  include AuthDoorkeeper
  before_action :auto_authenticate_omniauth_user!
RUBY
create_file 'app/controllers/concerns/auth_doorkeeper.rb', <<-'RUBY'
module AuthDoorkeeper
  private def auto_authenticate_omniauth_user!
    return if current_user
    session[:user_return_to] = request.original_url
    redirect_to main_app.user_doorkeeper_omniauth_authorize_path
  end
end
RUBY

git_commit 'Setup doorkeeper auth'

generate 'migration', 'AddOmniauthColumnsToUsers', 'provider:string', 'uid:string'
migration_file, = Dir.glob('db/migrate/*_add_omniauth_columns_to_users.rb')
insert_into_file migration_file, <<-'RUBY', before: /^  end$/
    add_index :users, [:provider, :uid]
RUBY
inject_into_class 'app/models/user.rb', 'User', <<-'RUBY'
  validates :provider, :uid, presence: true
RUBY
gsub_file 'db/seeds.rb', %q(attributes = { email: admin_email, name: 'Admin User' }), %q(attributes = { email: admin_email, name: 'Admin User', provider: 'doorkeeper', uid: '1' })
insert_into_file 'spec/factories/users.rb', <<-'RUBY', after: /:password.*\n/
    sequence(:provider) { |n| "provider#{n}" }
    sequence(:uid) { |n| "uid#{n}" }
RUBY
git_commit 'Add Omniauth columns to users'

rake_db_migrate
