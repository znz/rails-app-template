# -*- coding: utf-8 -*-
# confirmed version:
# * rails 4.0.0
# * the_role 2.1.1
# * bootstrap-sass 2.3.2.2
# * devise 3.1.1

unless /the_role/ =~ File.read('Gemfile')
  gem 'bootstrap-sass'
  gem 'the_role'
  abort('run again after `bundle install`')
end

create_file 'db/migrate/1070_add_role_id_to_users.rb', <<-RUBY
class AddRoleIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :role_id, :integer
  end
end
RUBY

insert_into_file 'app/models/user.rb', <<-RUBY, after: /class User.*\n/
  include TheRoleUserModel
RUBY

generate 'the_role install'
gsub_file 'config/initializers/the_role.rb', /\r\n|(?<!\n)\z/, "\n"

run 'rake the_role_engine:install:migrations'
create_roles = 'db/migrate/7000_create_roles.the_role_engine.rb'
f, = Dir['db/migrate/*_create_roles.the_role_engine.rb']
if f != create_roles
  FileUtils::Verbose.mv f, create_roles
end
#run 'rake db:migrate'
#generate 'the_role admin'
#User.first.update( role: Role.with_name(:admin) )

insert_into_file 'app/controllers/application_controller.rb', <<-RUBY, after: /class ApplicationController.*\n/
  include TheRoleController
RUBY

login_require =
  case File.read('Gemfile')
  when /devise/
    :authenticate_user!
  when /sorcery/
    :require_login
  else
    :user_require_method
  end
insert_into_file 'app/controllers/application_controller.rb', <<-RUBY, before: /^end/

  # your Access Denied processor
  def access_denied
    return render(text: 'access_denied: requires a role')
  end

  # Define method aliases for the correct TheRole's controller work
  alias_method :login_required,     :#{login_require}
  alias_method :role_access_denied, :access_denied
RUBY

apply File.expand_path('../app-assets.rb', __FILE__)

create_file 'app/assets/stylesheets/roles.css', <<-RUBY
/*
 *= require_self
 *= require the_role/bootstrap_sass
 *= require the_role
 *= require_directory ./roles
 */
RUBY
create_file 'app/assets/stylesheets/roles/.keep'
create_file 'app/assets/javascripts/roles.js', <<-RUBY
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap
//= require the_role
//= require_directory ./roles
RUBY
create_file 'app/assets/javascripts/roles/.keep'

create_file 'app/views/layouts/roles.html.haml', <<-HAML
!!! 5
%html(lang="ja")
  %head
    %meta(charset="utf-8")
    %meta(http-equiv="X-UA-Compatible" content="IE=edge,chrome=1")
    %meta(name="viewport" content="width=device-width, initial-scale=1")
    %title= @app_name ||= 'The Role'
    = csrf_meta_tags
    /[if lt IE 9]
      = javascript_include_tag "//cdnjs.cloudflare.com/ajax/libs/html5shiv/3.6.1/html5shiv.js"
    = stylesheet_link_tag "roles", media: "all"
    = javascript_include_tag "roles"
  %body
    #main(role="main")
      .container-fluid
        .row-fluid
          .span3
            = yield :role_sidebar
          .span9
            = yield :role_main
HAML
gsub_file 'config/initializers/the_role.rb', ':application', ':roles'
