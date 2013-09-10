# -*- coding: utf-8 -*-
# usage:
#  rake rails:template LOCATION=path/to/secret_token.rb

create_file 'config/initializers/secret_token.rb' do
  <<-RUBY
# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
require 'securerandom'

def secure_token(token_file_name='.secret')
  token_file = Rails.root.join(token_file_name)
  if File.exist?(token_file)
    # Use the existing token.
    File.read(token_file).chomp
  else
    # Generate a new token and store it in token_file.
    token = SecureRandom.hex(64)
    File.write(token_file, token)
    token
  end
end

Rails.application.config.secret_key_base = ENV['SECRET_TOKEN'] || secure_token
  RUBY
end
