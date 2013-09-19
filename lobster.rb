# -*- coding: utf-8 -*-
route <<-'RUBY'.chomp
if Rails.env.development? || Rails.env.test?
    require 'rack/lobster'
    mount Rack::Lobster.new => 'lobster', as: :lobster
  end
RUBY
create_file 'spec/features/lobster_spec.rb', <<-'RUBY'
require 'spec_helper'

describe "Lobster", js: ENV['USE_JS_DRIVER'] do
  subject { page }

  describe "flip" do
    before do
      visit lobster_path
      click_link "flip!"
    end
    its(:status_code) {
      begin
        should be(200)
      rescue Capybara::NotSupportedByDriverError => e
        pending e.message
      end
    }
    it { should have_title 'Lobstericious!' }
    its(:source) { should =~ /<title>Lobstericious!<\/title>/ }
  end

  describe "crash" do
    before { visit lobster_path }

    it "crash!" do
      if Capybara.current_driver == :rack_test
        expect do
          click_link "crash!"
        end.to raise_error(RuntimeError, "Lobster crashed")
      else
        click_link "crash!"
        should have_no_title "Lobstericious!"
        Capybara.current_session.server.reset_error!
      end
    end
  end
end
RUBY
