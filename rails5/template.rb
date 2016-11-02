# -*- coding: utf-8 -*-
# frozen_string_literal: true

DEFAULT_PORT = 4000
RAILS_I18N_VERSION = '5.0.0'

require_relative 'util'

git :init
git_commit 'Initial commit'
bundle_install
git_commit '`bundle install`'

gsub_file 'Gemfile', /\n{3,}/, "\n\n"
create_file '.ruby-version', "#{RUBY_VERSION}\n"
insert_into_file 'Gemfile', "ruby File.read('.ruby-version')\n", after: "source 'https://rubygems.org'\n"
git_commit 'Add .ruby-version'

comment_lines 'Gemfile', /jbuilder/
git_commit 'Comment out jbuilder gem'

gsub_file 'Gemfile', /gem 'sqlite3'/, "gem 'sqlite3', group: [:development, :test]\ngem 'pg', group: :postgresql"
git_commit 'Use pg gem'

gem_bundle 'rails-i18n', "~> #{RAILS_I18N_VERSION}"
initializer 'default_locale.rb', <<-RUBY
I18n.enforce_available_locales = true
Rails.application.config.i18n.available_locales = %i[en ja]
Rails.application.config.i18n.default_locale = 'ja'
RUBY
git_commit 'Set default locale'

if false
  # does not work?
  initializer 'time_zone.rb', <<-RUBY
Rails.application.config.time_zone = 'Tokyo'
  RUBY
else
  environment %q(config.time_zone = 'Tokyo')
end
git_commit 'Set default time zone'

initializer 'generators.rb', <<-RUBY
Rails.application.config.generators do |g|
  g.assets        false # javascripts and stylesheets
  g.helper        false
  g.helper_specs  false
  g.javascripts   false
  g.stylesheets   false
  g.view_specs    false
  g.request_specs false
end
RUBY
git_commit 'Disable unused file generators'

append_file 'config/initializers/inflections.rb', <<-'RUBY'

ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural(/([^!-~])$/, '\\1')
  inflect.singular(/([^!-~])$/, '\\1')
end
RUBY
git_commit 'Update inflections'

create_file 'config/locales/attributes.ja.yml', <<-'YAML'
ja:
  attributes:
    id: "ID"
    created_at: "作成日時"
    updated_at: "更新日時"
YAML
git_commit 'Add default translations of attributes'

gem_bundle 'dotenv-rails', group: [:development, :test] do
  append_file '.gitignore', "\n\# Ignore dotenv files.\n.env.*\n"
  create_file '.env', <<-'ENV'
MAIL_FROM=from@example.com
  ENV
end

gem_bundle 'bootstrap-sass' do
  copy_file 'app/assets/stylesheets/application.css', 'app/assets/stylesheets/application.scss'
  remove_file 'app/assets/stylesheets/application.css'
  insert_into_file 'app/assets/javascripts/application.js', "//= require bootstrap-sprockets\n", before: "//= require_tree ."
  append_file 'app/assets/stylesheets/application.scss', <<-SCSS

// "bootstrap-sprockets" must be imported before "bootstrap" and "bootstrap/variables"
@import "bootstrap-sprockets";
@import "bootstrap";
  SCSS
end

gem_bundle 'font-awesome-sass' do
  append_file 'app/assets/stylesheets/application.scss', <<-SCSS

@import "font-awesome-sprockets";
@import "font-awesome";
  SCSS
end

gem_bundle 'slim-rails'
remove_file 'app/views/layouts/application.html.erb'
create_file 'app/views/layouts/application.html.slim', <<-'SLIM'
doctype html
html
  head
    meta charset="utf-8"
    meta http-equiv="X-UA-Compatible" content="IE=edge"
    meta name="viewport" content="width=device-width, initial-scale=1"
    meta name="format-detection" content="telephone=no"
    title
      = yield(:title)
    = csrf_meta_tags
    /[if lt IE 9]
      script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"
      script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"
    = stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload'
    = javascript_include_tag 'application', 'data-turbolinks-track': 'reload'
    = yield(:head)
  body
    noscript
      div(id="noscript-warning")= t(:'layout.noscript_warning')
    .container#main role="main"
      = yield
SLIM
create_file 'config/locales/layout.en.yml', <<-'YAML'
en:
  layout:
    noscript_warning: "This site works best with JavaScript enabled"
YAML
create_file 'config/locales/layout.ja.yml', <<-'YAML'
ja:
  layout:
    noscript_warning: "JavaScript を有効にするとすべての機能が使えます"
YAML
git_commit 'Update layout'

gem_bundle 'simple_form', generator: %w[simple_form:install --bootstrap] do
  create_file 'config/locales/simple_form.ja.yml', <<-'YAML'
ja:
  simple_form:
    "yes": 'はい'
    "no": 'いいえ'
    required:
      text: '必須'
      mark: '(必須)'
    error_notification:
      default_message: "以下の問題を修正してください:"
  YAML
end

gem_bundle 'kaminari'
gem_bundle 'kaminari-i18n' do
  create_file 'config/locales/kaminari.ja.yml', <<-'YAML'
ja:
  helpers:
    page_entries_info:
      one_page:
        display_entries:
          zero: "%{entry_name}はありません。"
          one: "<b>1</b>件の%{entry_name}を表示しています。"
          other: "<b>%{count}</b>件すべての%{entry_name}を表示しています。"
      more_pages:
        display_entries: "<b>%{total}</b>件中<b>%{first}</b>から<b>%{last}</b>番目の%{entry_name}を表示しています。"
  YAML
end
gem_bundle 'ransack'

create_file 'app/helpers/query_params_helper.rb', <<-'RUBY'
# this module includes in controller too
module QueryParamsHelper
  def params_q(new_params = nil)
    if @params_q.blank?
      p_q = params.fetch(:q, {})
      @params_q = p_q
    else
      p_q = @params_q
    end
    if new_params
      p_q = p_q.merge(new_params)
    end
    p_q.keys.each do |key|
      p_q.delete(key) if p_q[key].nil?
    end
    p_q
  end

  def params_page
    page = params[:page]
    if page
      page.to_i
    end
  end

  def params_per_page(default = 5)
    per_page = params[:per].to_i
    unless [1, 3, 5, 10, 20, 50].include?(per_page)
      if block_given?
        return yield(per_page)
      else
        return default
      end
    end
    per_page
  end

  def params_table
    params[:table] ? 1 : nil
  end
end
RUBY
insert_into_file 'app/controllers/application_controller.rb', <<-'RUBY', before: /^end/
  include QueryParamsHelper
RUBY
create_file 'config/locales/flash.en.yml', <<-'YAML'
en:
  flash:
    notice:
      model_was_successfully_created: "%{model} was successfully created."
      model_was_successfully_updated: "%{model} was successfully updated."
      model_was_successfully_destroyed: "%{model} was successfully destroyed."
YAML
create_file 'config/locales/flash.ja.yml', <<-'YAML'
ja:
  flash:
    notice:
      model_was_successfully_created: "%{model} を作成しました。"
      model_was_successfully_updated: "%{model} を更新しました。"
      model_was_successfully_destroyed: "%{model} を削除しました。"
YAML
scaffold_controller_template = 'lib/templates/rails/scaffold_controller/controller.rb'
copy_file Gem.find_latest_files('rails/generators/rails/scaffold_controller/templates/controller.rb')[0], scaffold_controller_template
gsub_file scaffold_controller_template, /before_action .*/, 'load_and_authorize_resource'
gsub_file scaffold_controller_template, '    @<%= plural_table_name %> = <%= orm_class.all(class_name) %>', <<-'RUBY'.chomp
    @q = @<%= plural_table_name %>.search(params_q)
    @q.sorts = 'id desc' if @q.sorts.empty?
    @<%= plural_table_name %> = @q.result(distinct: true)
    @<%= plural_table_name %> = @<%= plural_table_name %>.page(params_page)
    @<%= plural_table_name %> = @<%= plural_table_name %>.per(params_per_page)
RUBY
gsub_file scaffold_controller_template, /def new\n.*/, 'def new'
gsub_file scaffold_controller_template, /def create\n.*\n/, 'def create'
gsub_file scaffold_controller_template, /.*redirect_to.*created.*/, <<-'RUBY'.chomp
      flash[:notice] = t('flash.notice.model_was_successfully_created', model: <%= class_name %>.model_name.human)
      redirect_to @<%= singular_table_name %>
RUBY
gsub_file scaffold_controller_template, /.*redirect_to.*updated.*/, <<-'RUBY'.chomp
      flash[:notice] = t('flash.notice.model_was_successfully_updated', model: <%= class_name %>.model_name.human)
      redirect_to @<%= singular_table_name %>
RUBY
gsub_file scaffold_controller_template, /.*redirect_to.*destroyed.*/, <<-'RUBY'.chomp
    flash[:notice] = t('flash.notice.model_was_successfully_destroyed', model: <%= class_name %>.model_name.human)
    redirect_to <%= index_helper %>_url
RUBY
gsub_file scaffold_controller_template, /^\s*private[\s\S]+(?=^end)/, <<-'RUBY'

  private def <%= "#{singular_table_name}_params" %>
    <%- if attributes_names.empty? -%>
    params.fetch(:<%= singular_table_name %>, {})
    <%- else -%>
    params.require(:<%= singular_table_name %>).permit(<%= attributes_names.map { |name| ":#{name}" }.join(', ') %>)
    <%- end -%>
  end
RUBY
create_file 'config/locales/helpers.en.yml', <<-'YAML'
en:
  helpers:
    actions: "Actions"
    links:
      back: "Back"
      cancel: "Cancel"
      confirm: "Are you sure?"
      destroy: "Destroy"
      edit: "Edit"
      new: "New"
      show: "Show"
      search: "Search"
      remove_search: "Remove Search Conditions"
      next_page: "Next page"
    titles:
      create: :helpers.titles.new
      edit: "Editing %{model}"
      index: "Listing %{models}"
      new: "New %{model}"
      show: "%{model}"
      update: :helpers.titles.edit
YAML
create_file 'config/locales/helpers.ja.yml', <<-'YAML'
ja:
  helpers:
    actions: "動作"
    links:
      back: "戻る"
      cancel: "キャンセル"
      confirm: "本当に削除しますか?"
      destroy: "削除"
      edit: "編集"
      new: "新規作成"
      show: "詳細"
      search: "検索"
      remove_search: "検索解除"
      next_page: "次のページ"
    titles:
      create: :helpers.titles.new
      edit: "%{model}編集"
      index: "%{models}一覧"
      new: "新規%{model}"
      show: "%{model}詳細"
      update: :helpers.titles.edit
YAML
create_file 'app/helpers/link_to_helper.rb', <<-'RUBY'
# frozen_string_literal: true
module LinkToHelper
  def link_to_back(options, html_options = {})
    html_options = { class: 'btn btn-default' }.merge(html_options)
    body = html_options.delete(:body) || t('.back', default: :'helpers.links.back')
    link_to body, options, html_options
  end

  def link_to_cancel(options, html_options = {})
    html_options = { class: 'btn btn-default' }.merge(html_options)
    body = html_options.delete(:body) || t('.cancel', default: :'helpers.links.cancel')
    link_to body, options, html_options
  end

  def link_to_destroy(record, options = nil, html_options = {})
    return if record.new_record?
    return unless can? :destroy, record
    options ||= record
    html_options = {
      data: { confirm: t('.confirm', default: [:'helpers.links.confirm', 'Are you sure?']), },
      method: :delete,
    }.deep_merge(html_options)
    case action_name
    when 'index'
      html_options = { class: 'btn btn-danger btn-xs' }.merge(html_options)
    else
      html_options = { class: 'btn btn-danger' }.merge(html_options)
    end
    body = html_options.delete(:body) || icon(:'trash-o') + t('.destroy', default: :'helpers.links.destroy')
    link_to body, options, html_options
  end

  def link_to_edit(record, options = nil, html_options = {})
    return unless can? :edit, record
    options ||= [:edit, *record]
    case action_name
    when 'index'
      html_options = { class: 'btn btn-default btn-xs' }.merge(html_options)
    else
      html_options = { class: 'btn btn-primary' }.merge(html_options)
    end
    body = html_options.delete(:body) || icon(:pencil) + t('.edit', default: :'helpers.links.edit')
    link_to body, options, html_options
  end

  def link_to_new(model_class, options = nil, html_options = {})
    return unless can? :create, model_class
    options ||= [:new, *model_class.name.underscore.split('/')]
    html_options = { class: 'btn btn-success' }.merge(html_options)
    body = html_options.delete(:body) || icon(:plus) + t('.new', default: :'helpers.links.new')
    link_to body, options, html_options
  end

  def link_to_show(record, options = nil, html_options = {})
    return if record.new_record?
    return unless can? :read, record
    options ||= record
    case action_name
    when 'index'
      html_options = { class: 'btn btn-default btn-xs' }.merge(html_options)
    else
      html_options = { class: 'btn btn-default' }.merge(html_options)
    end
    body = html_options.delete(:body) || t('.show', default: :'helpers.links.show')
    link_to body, options, html_options
  end

  def link_to_remove_search(link, show = params_q.present?)
    if show
      link_to icon(:times)+t(:'helpers.links.remove_search'), link, class: 'btn btn-warning'.freeze
    end
  end

  def link_to_next_page_or_new(entries, model_class, options=nil)
    if entries.last_page?
      if model_class
        link_to_new model_class, options, class: 'btn btn-lg btn-block btn-success'.freeze
      end
    else
      table = params[:table] ? 1 : nil
      link_to_next_page entries, t(:'helpers.links.next_page'), params: { table: table, q: params_q }, class: 'btn btn-lg btn-block btn-success'.freeze
    end
  end
end
RUBY
create_file 'app/helpers/title_helper.rb', <<-'RUBY'
# frozen_string_literal: true
module TitleHelper
  def sub_title(title, options=nil)
    provide :title, title
    content_tag(:h2, title, options)
  end
end
RUBY
create_file 'app/views/shared/_paginate_with_info.html.slim', <<-'SLIM'
.row.pagination-with-info
  .col-xs-12
    .pull-left= page_entries_info entries, entry_name: entries.model_name.human
    .pull-right= paginate entries
SLIM
remove_file 'lib/templates/slim/scaffold/_form.html.slim'
create_file 'lib/templates/slim/scaffold/_form.html.slim', <<-'SLIM'
- model_class = <%= class_name %>
= sub_title t('.title', default: :"helpers.titles.#{action_name}", model: model_class.model_name.human)
= simple_form_for @<%= singular_table_name %>, wrapper: :horizontal_form, html: { class: 'form-horizontal' } do |f|
  = f.error_notification

<%- attributes.each do |attribute| -%>
  = f.<%= attribute.reference? ? :association : :input %> :<%= attribute.name %>
<%- end -%>

  .form-group
    .col-md-10.col-md-offset-2
      = link_to_cancel :<%= plural_table_name %>
      '
      = link_to_show @<%= singular_table_name %>
      '
      = f.submit nil, class: 'btn btn-primary'
SLIM
create_file 'lib/templates/slim/scaffold/edit.html.slim', <<-'SLIM'
== render 'form'
SLIM
create_file 'lib/templates/slim/scaffold/index.html.slim', <<-'SLIM'
- model_class = <%= class_name %>
= sub_title t('.title', default: :'helpers.titles.index', models: model_class.model_name.human.pluralize)
.well
  = search_form_for @q, html: { class: 'form-horizontal' } do |f|
<% attributes.each do |attribute| -%>
  <%- unless attribute.reference? -%>
    .form-group
      .col-md-2
        = f.label :<%= attribute.name %>_cont
      .col-md-10
        = f.text_field :<%= attribute.name %>_cont, class: 'form-control', placeholder: model_class.human_attribute_name(:<%= attribute.name %>)
  <%- end -%>
<% end -%>
    .form-group
      .col-md-offset-2.col-md-10
        = f.button icon(:search)+t(:'helpers.links.search'), class: 'btn btn-primary'
        '
        = link_to_remove_search(:<%= plural_table_name %>)
= render partial: "shared/paginate_with_info", locals: { entries: @<%= plural_table_name %> }
table.table.table-striped.table-hover
  thead
    tr
      th= sort_link @q, :id
<% attributes.each do |attribute| -%>
      th= sort_link @q, :<%= attribute.name %>
<% end -%>
      th= t '.actions', default: :'helpers.actions'

  tbody
    - @<%= plural_table_name %>.each do |<%= singular_table_name %>|
      tr
        td= link_to <%= singular_table_name %>.id, <%= singular_table_name %>
<% attributes.each do |attribute| -%>
        td= <%= singular_table_name %>.<%= attribute.name %>
<% end -%>
        td
          = link_to_show <%= singular_table_name %>
          = link_to_edit <%= singular_table_name %>
          = link_to_destroy <%= singular_table_name %>
= link_to_next_page_or_new @<%= plural_table_name %>, model_class
= render partial: "shared/paginate_with_info", locals: { entries: @<%= plural_table_name %> }
SLIM
create_file 'lib/templates/slim/scaffold/new.html.slim', <<-'SLIM'
== render 'form'
SLIM
create_file 'lib/templates/slim/scaffold/show.html.slim', <<-'SLIM'
- model_class = <%= class_name %>
= sub_title t('.title', default: :"helpers.titles.#{action_name}", model: model_class.model_name.human)

.<%= singular_table_name.dasherize %> id="<%= singular_table_name %>_#{@<%= singular_table_name %>.id}"
  dl.dl-horizontal
  <%- attributes.each do |attribute| -%>
    dt= model_class.human_attribute_name(:<%= attribute.name %>)
    dd= @<%= singular_table_name %>.<%= attribute.name %>
  <%- end -%>
    dt= model_class.human_attribute_name(:created_at)
    dd= l(@<%= singular_table_name %>.created_at, format: :long)

.form-actions
  = link_to_back :<%= plural_table_name %>, body: t(:'helpers.titles.index', models: model_class.model_name.human.pluralize)
  '
  = link_to_destroy @<%= singular_table_name %>
  '
  = link_to_edit @<%= singular_table_name %>
SLIM
git_commit 'Update scaffold controller template'

gem_bundle 'rspec-rails', group: [:development, :test], generator: %w[rspec:install]
uncomment_lines 'spec/rails_helper.rb', Regexp.new(Regexp.quote(%q[Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }]))
gem_bundle 'factory_girl_rails', group: [:development, :test]
gem_bundle 'rails-controller-testing', group: :test
gem_bundle 'database_rewinder' do
  create_file 'spec/support/database_rewinder.rb', <<-RUBY
RSpec.configure do |config|
  config.before :suite do
    DatabaseRewinder.clean_all
  end

  config.after :each do
    DatabaseRewinder.clean
  end
end
  RUBY
end

append_file 'config/boot.rb', <<-RUBY
require 'rails/commands/server'
module Rails
  class Server
    def default_options
      super.merge(Port: #{DEFAULT_PORT})
    end
  end
end
RUBY
git_commit "Use #{DEFAULT_PORT} as default server port"

environment "config.action_mailer.smtp_settings = { address: 'localhost', port: 1025 }", env: 'development'
environment "config.action_mailer.delivery_method = :smtp", env: 'development'
environment "config.action_mailer.default_url_options = { host: 'localhost', port: #{DEFAULT_PORT} }", env: 'development'
find_executable('mailcatcher')
git_commit 'Setup action mailer to use mailcatcher'

create_file 'Procfile.dev', <<-'EOF'
web: rails server
mail: mailcatcher -f
EOF
find_executable('foreman')
git_commit 'Add Procfile.dev'

gem_bundle 'devise', generator: %w[devise:install] do
  gsub_file 'config/initializers/filter_parameter_logging.rb', /:password/, ':password, :password_confirmation'
end
gem_bundle 'omniauth' do
  gem 'omniauth-facebook'
  gem 'omniauth-github'
  gem 'omniauth-google-oauth2'
  gem 'omniauth-twitter'
  bundle_install
end
generate 'devise', 'User'
git_commit 'generate devise User'
gem_bundle 'cancancan' do
  generate 'cancan:ability'
end
gem_bundle 'rolify' do
  generate 'rolify', 'Role', 'User'
end

migration_file, = Dir.glob('db/migrate/*_devise_create_users.rb')
gsub_file migration_file, /\# t\./, "t."
gsub_file migration_file, /\# add_index/, "add_index"
gsub_file migration_file, /\n\n\n/, <<-RUBY

      t.string :name, null: false
      t.datetime :deleted_at

RUBY
rake_db_migrate
inject_into_class 'app/models/user.rb', 'User', "  NAME_MAX = 100\n  validates :name, presence: true, length: { maximum: NAME_MAX }\n"
inject_into_class 'app/models/user.rb', 'User', "  scope :active, -> { where(deleted_at: nil) }\n"
gsub_file 'app/models/user.rb', /^  devise /, "  devise :confirmable, :lockable, :timeoutable, :omniauthable,\n         "
remove_file 'spec/factories/users.rb'
create_file 'spec/factories/users.rb', <<-'RUBY'
FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Person #{n}" }
    sequence(:email) { |n| "person_#{n}@example.com" }
    sequence(:password) { |n| sprintf("dummy%03d", n) }

    after :create do |user|
      user.confirm if Devise.mappings[:user].confirmable?
    end

    factory :admin do
      after :create do |user|
        user.add_role 'admin'
      end
    end
  end
end
RUBY
remove_file 'spec/models/user_spec.rb'
create_file 'spec/models/user_spec.rb', <<-'RUBY'
require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { FactoryGirl.build(:user) }
  it { is_expected.to be_a User }
  it { should be_valid }
end
RUBY
git_commit 'Update user'

create_file 'spec/support/devise.rb', <<-'RUBY'
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
end
RUBY
git_commit 'Setup devise test helper'

remove_file 'spec/factories/roles.rb'
create_file 'spec/factories/roles.rb', <<-'RUBY'
FactoryGirl.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
  end
end
RUBY
remove_file 'spec/models/role_spec.rb'
create_file 'spec/models/role_spec.rb', <<-'RUBY'
require 'rails_helper'

RSpec.describe Role, type: :model do
  subject(:role) { FactoryGirl.create(:role) }
  it { is_expected.to be_a Role }
end
RUBY
create_file 'config/locales/role.en.yml', <<-YAML
en:
  role:
    admin: "Administrator"
YAML
create_file 'config/locales/role.ja.yml', <<-YAML
ja:
  role:
    admin: "管理者"
YAML
git_commit 'Update role'

environment "config.action_mailer.default_url_options = { host: 'example.com' }", env: 'test'
gsub_file 'app/mailers/application_mailer.rb', "'from@example.com'", "ENV['MAIL_FROM']"
gsub_file 'config/initializers/devise.rb', "'please-change-me-at-config-initializers-devise@example.com'", "ENV['MAIL_FROM']"
git_commit 'Setup action_mailer'

gem_bundle 'devise-i18n'
generate 'devise:i18n:views'
git_commit 'Generate devise:i18n:views'

find_executable('erb2slim', gem: 'html2slim')
Dir.glob('app/views/devise/**/*.erb') do |erb|
  next if /\.text\./ =~ erb
  run "erb2slim -d #{erb} #{erb.sub(/\.erb\z/, '.slim')}"
end
gsub_file 'app/views/devise/mailer/password_change.html.slim', /^.*require.*\n$/, '' # remove unused require
git_commit '`erb2slim`'

insert_into_file 'app/views/devise/registrations/new.html.slim', "    = f.input :name, required: true\n", after: /autofocus: true\n/
create_file 'config/locales/user.ja.yml', <<-YAML
ja:
  activerecord:
    attributes:
      user:
        name: "名前"
        deleted_at: "削除日時"
YAML
insert_into_file 'app/controllers/application_controller.rb', <<-'RUBY', before: /^end/

  before_action :configure_permitted_parameters, if: :devise_controller?

  private def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      parameters = [
        :name,
        :email,
        :password, :password_confirmation,
      ]
      u.permit(*parameters)
    end

    devise_parameter_sanitizer.permit(:account_update) do |u|
      parameters = [
        :name,
        # :email, # disallow to change email
        :password, :password_confirmation,
      ]
      u.permit(*parameters)
    end
  end
RUBY
Dir.glob('app/views/devise/mailer/*.slim') do |slim|
  gsub_file slim, '@resource.email', '@resource.name'
end
git_commit 'Add name to devise views'

insert_into_file 'app/controllers/application_controller.rb', <<-'RUBY', before: /^end/
  before_action :authenticate_active_user!

  private def authenticate_active_user!
    User.active.scoping do
      authenticate_user!
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, alert: exception.message
  end
RUBY
insert_into_file 'app/models/ability.rb', <<-'RUBY', after: /def initialize\(user\)\n/
    user ||= User.new # guest user (not logged in)
    case
    when user.has_role?(:admin)
      can :manage, :all
    when user.persisted?
      can :read, :all
    end
RUBY
git_commit 'Add authentication and authorization'

uncomment_lines 'public/robots.txt', /(User-agent|Disallow):/
git_commit 'Disallow from robots'

append_file 'db/seeds.rb', <<-'RUBY'

if Rails.env.development?
  admin_email = 'admin@example.com'
  admin = User.where(email: admin_email).first
  unless admin
    admin = User.create!(email: admin_email, name: 'Admin User', password: 'adminpass')
    admin.confirm if Devise.mappings[:user].confirmable?
  end
  unless admin.has_role? 'admin'
    admin.add_role 'admin'
  end
end
RUBY
