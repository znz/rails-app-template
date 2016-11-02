gsub_file 'Gemfile', /^gem 'sqlite3'$/ do
  <<-GEMFILE
group :development, :test do
  gem 'sqlite3'
end
group :production do
  gem 'pg'
  gem 'rails_12factor'
end
  GEMFILE
end
