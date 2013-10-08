# -*- coding: utf-8 -*-
insert_into_file 'app/policies/application_policy.rb', <<-'RUBY', before: /^end/

  def rails_admin?(action)
    case action
    when :index
      index?
    when :show
      show?
    when :create
      create?
    when :new
      new?
    when :update
      update?
    when :edit
      edit?
    when :destroy
      destroy?
    when :export
      index?
    when :history
      index?
    when :show_in_app
      show?
    else
      raise ::Pundit::NotDefinedError, "unable to find policy #{action} for #{record}."
    end
  end
RUBY

create_file 'app/policies/rails_admin_policy.rb', <<-'RUBY'
class RailsAdminPolicy < ApplicationPolicy
  def initialize(user, record=nil)
    super
  end

  def rails_admin?(action)
    case action
    when :dashboard
      true
    else
      super
    end
  end
end
RUBY

create_file 'lib/rails_admin/extensions/pundit.rb', <<-'RUBY'
require 'rails_admin/extensions/pundit/authorization_adapter'

RailsAdmin.add_extension(:pundit, RailsAdmin::Extensions::Pundit, {
  :authorization => true
})
RUBY

create_file 'lib/rails_admin/extensions/pundit/authorization_adapter.rb', <<-'RUBY'
module RailsAdmin
  module Extensions
    module Pundit
      class AuthorizationAdapter
        def initialize(controller)
          @controller = controller
        end

        def policy(record)
          if record
            @controller.policy(record)
          else
            ::RailsAdminPolicy.new(@controller.current_user)
          end
        end
        private :policy

        def authorize(action, abstract_model = nil, model_object = nil)
          record = model_object || abstract_model && abstract_model.model
          unless policy(record).rails_admin?(action)
            raise ::Pundit::NotAuthorizedError, "not allowed to #{action} this #{record}"
          end
        end

        def authorized?(action, abstract_model = nil, model_object = nil)
          record = model_object || abstract_model && abstract_model.model
          policy(record).rails_admin?(action)
        end

        def query(action, abstract_model)
          @controller.policy_scope(abstract_model.model.scoped)
        end
      end
    end
  end
end
RUBY

insert_into_file 'config/initializers/rails_admin.rb', <<-'RUBY', before: /^end/

  require 'rails_admin/extensions/pundit'
  config.authorize_with :pundit
RUBY
