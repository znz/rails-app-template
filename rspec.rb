# -*- coding: utf-8 -*-

javascript_driver = ENV["JAVASCRIPT_DRIVER"]
#javascript_driver ||= "webkit"
javascript_driver ||= "poltergeist"
javascript_driver = javascript_driver.to_sym

unless /rspec-rails/ =~ File.read('Gemfile')
  gem_group :development, :test do
    gem 'rspec-rails'
    gem 'factory_girl_rails'
  end
  gem_group :test do
    # https://github.com/bmabey/database_cleaner/issues/224
    # database_cleaner 1.1.[01] are broken for SQlite3
    # (when DatabaseCleaner.strategy = :truncation)
    gem 'database_cleaner', '< 1.1.0'
    gem 'email_spec'
    gem 'turnip'
    gem 'capybara'
    case javascript_driver
    when :webkit
      gem 'capybara-webkit'
    when :poltergeist
      gem 'poltergeist'
    end
  end
  abort('run again after `bundle install`')
end

generate 'rspec:install'

case javascript_driver
when :webkit
  create_file "spec/support/javascript_driver.rb", <<-RUBY
# -*- coding: utf-8 -*-
Capybara.javascript_driver = :webkit
  RUBY
when :poltergeist
  create_file "spec/support/javascript_driver.rb", <<-RUBY
# -*- coding: utf-8 -*-
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
  RUBY
end

create_file "spec/support/database_cleaner.rb", <<-RUBY
# -*- coding: utf-8 -*-
RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before :each do
    if Capybara.current_driver == :rack_test
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
    else
      DatabaseCleaner.strategy = :truncation
    end
  end

  config.after :each do
    count = 0
    begin
      DatabaseCleaner.clean
    rescue
      # avoid SQLite3::BusyException
      count += 1
      if count < 5
        sleep 0.1
        retry
      end
      raise
    end
  end
end
RUBY
