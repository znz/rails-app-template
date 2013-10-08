# -*- coding: utf-8 -*-
unless /pundit/ =~ File.read('Gemfile')
  gem 'pundit'
  abort('run again after `bundle install`')
end

insert_into_file 'app/controllers/application_controller.rb', <<-'RUBY', after: /class ApplicationController.*\n/
  include Pundit
RUBY

insert_into_file 'app/controllers/application_controller.rb', <<-'RUBY', before: /^end/

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def user_not_authorized
    flash[:alert] = I18n.t(:'pundit.user_not_authorized', default: "You are not authorized to perform this action.")
    redirect_to request.headers["Referer"] || main_app.root_path
  end
  private :user_not_authorized
RUBY
create_file 'config/locales/pundit.ja.yml', <<-YAML
ja:
  pundit:
    user_not_authorized: "許可されていない操作です。"
YAML

generate 'pundit:install'

if /rails_admin/ =~ File.read('Gemfile')
  apply File.expand_path('../pundit-with-rails_admin.rb', __FILE__)
end
apply File.expand_path('../pundit-with-scaffold.rb', __FILE__)
