# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'rake'
  gem 'rspec-rails'
  gem 'smtp_mock'

  gem 'debug'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false

  gem 'rails', "~> #{ENV['RAILS_VERSION'] || '7.2.0' }"
  gem 'sqlite3', '~> 1.4'
end
