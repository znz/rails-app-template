# -*- coding: utf-8 -*-
# frozen_string_literal: true

TEST_MODE = ENV.fetch('TEST_MODE') { false }

require 'shellwords'

def git_commit(message)
  git add: '.'
  git commit: "-am #{Shellwords.escape(message)} --no-verify"
end

def bundle_install
  require 'bundler'
  Bundler.with_clean_env do
    if TEST_MODE
      run 'bundle install --local >/dev/null'
    else
      run 'bundle install'
    end
  end
end

def bundle_update
  require 'bundler'
  Bundler.with_clean_env do
    run 'bundle update'
  end
end

def gem_bundle(name, version = nil, message: "Use #{name} gem", group: false, generator: false)
  options = {}
  if group
    options[:group] = group
  end
  if version
    gem name, version, options
  else
    gem name, options
  end
  bundle_install
  generate(*generator) if generator
  yield if block_given?
  git_commit message
end

def rake_db_migrate
  rake 'db:migrate'
  git_commit '`rake db:migrate`'
end

def find_executable(exe, gem: exe)
  unless ENV["PATH"].split(File::PATH_SEPARATOR).any? { |path| File.executable?("#{path}/#{exe}#{RbConfig::CONFIG['EXEEXT']}") }
    run "gem install #{gem}"
  end
end

def add_admin_sign_in_to_controller_spec(spec)
  insert_into_file spec, <<-'RUBY', after: /^RSpec\.describe .* do\n/
  let(:admin_user) { FactoryGirl.create(:admin) }
  before { sign_in admin_user }
  RUBY
end

module CheckedGsubFile
  def gsub_file(path, flag, *args, &block)
    data = File.binread(path)
    case flag
    when Regexp
      unless flag =~ data
        raise "#{flag.inspect} not found in #{path}"
      end
    when String
      unless data.index(flag)
        raise "#{flag.inspect} not found in #{path}"
      end
    end
    super
  end
end
Rails::Generators::AppGenerator.include CheckedGsubFile
