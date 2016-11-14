# -*- coding: utf-8 -*-
# frozen_string_literal: true
require_relative 'util'

generate 'scaffold_controller', 'User', 'email', 'name'
git_commit %q(rails generate scaffold_controller User)

route 'resources :users'
add_admin_sign_in_to_controller_spec 'spec/controllers/users_controller_spec.rb'
gsub_file 'app/controllers/users_controller.rb', 'params.require(:user).permit(:email, :name)', 'params.require(:user).permit(:email, :name, :password, :password_confirmation)'
gsub_file 'spec/controllers/users_controller_spec.rb', %Q[  let(:valid_attributes) {\n    skip("Add a hash of attributes valid for your model")\n  }\n], <<-'RUBY'
  let(:valid_attributes) do
    {
      email: 'email@example.com',
      name: 'name',
      password: 'password',
      password_confirmation: 'password',
    }
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
  = f.input :password, required: true
  = f.input :password_confirmation, required: true
SLIM
git_commit 'Update scaffold_controller of user'
