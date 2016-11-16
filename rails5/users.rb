# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

generate 'scaffold_controller', 'User', 'email', 'name'
git_commit %q(rails generate scaffold_controller User)

route 'resources :users'
add_admin_sign_in_to_controller_spec 'spec/controllers/users_controller_spec.rb'
gsub_file 'app/controllers/users_controller.rb', <<-'RUBY', <<-'RUBY'
    params.require(:user).permit(:email, :name)
RUBY
    attributes = [:email, :name]
    if User.new.respond_to?(:password=)
      attributes << :password << :password_confirmation
    end
    params.require(:user).permit(*attributes, roles_name: [])
RUBY
insert_into_file 'app/models/user.rb', <<-'RUBY', before: /^end/

  def roles_name=(names)
    I18n.t(:role).each do |key, _|
      key = key.to_s
      case
      when names.include?(key) && !has_role?(key)
        add_role(key)
      when !names.include?(key) && has_role?(key)
        remove_role(key)
      end
    end
  end
RUBY
gsub_file 'app/controllers/users_controller.rb', <<-'RUBY', <<-'RUBY'
  def update
    if @user.update(user_params)
RUBY
  def update
    updated = nil
    begin
      @user.transaction do
        @user.roles_name = user_params.fetch(:roles_name, [])
        @user.update!(user_params)
        updated = true
      end
    rescue ActiveRecord::RecordInvalid
      updated = false
    end
    if updated
RUBY
gsub_file 'spec/controllers/users_controller_spec.rb', %Q[  let(:valid_attributes) {\n    skip("Add a hash of attributes valid for your model")\n  }\n], <<-'RUBY'
  let(:valid_attributes) do
    attributes = {
      email: 'email@example.com',
      name: 'name',
    }
    if User.new.respond_to?(:password=)
      attributes[:password] = 'password'
      attributes[:password_confirmation] = attributes[:password]
    end
    attributes
  end
RUBY
gsub_file 'spec/controllers/users_controller_spec.rb', %Q[  let(:invalid_attributes) {\n    skip("Add a hash of attributes invalid for your model")\n  }\n], <<-'RUBY'
  let(:invalid_attributes) do
    {
      name: '',
    }
  end
RUBY
gsub_file 'spec/controllers/users_controller_spec.rb', %Q[      let(:new_attributes) {\n        skip("Add a hash of attributes valid for your model")\n      }\n], <<-'RUBY'
      let(:new_attributes) do
        {
          name: 'new name',
        }
      end
RUBY
gsub_file 'spec/controllers/users_controller_spec.rb', 'skip("Add assertions for updated state")', %q[expect(user.name).to eq 'new name']
gsub_file 'spec/controllers/users_controller_spec.rb', 'User.create! valid_attributes', 'FactoryGirl.create :user'
gsub_file 'spec/controllers/users_controller_spec.rb', 'expect(assigns(:users)).to eq([user])', 'expect(assigns(:users)).to match_array([admin_user, user])'
gsub_file 'app/views/users/_form.html.slim', <<-'SLIM', <<-'SLIM'
  = f.input :email

  = f.input :name

SLIM
  = f.input :email, required: true, autofocus: true
  = f.input :name, required: true
  - if f.object.respond_to?(:password=)
    = f.input :password, required: true
    = f.input :password_confirmation, required: true
  .form-group
    label.control-label.col-sm-3
      = User.human_attribute_name(:roles)
    .col-sm-9.form-labels
      - I18n.t(:role).each do |key, value|
        '
        label
          = check_box_tag 'user[roles_name][]', key, @user.has_role?(key), id: "user_role_#{key}"
          '
          = value
SLIM
create_file 'app/assets/stylesheets/form-labels.scss', <<-'SCSS'
.form-labels label {
  font-weight: normal;
}
SCSS
git_commit 'Update scaffold_controller of user'
