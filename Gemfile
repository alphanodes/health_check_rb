# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

if ENV['RAILS_VERSION'] == 'edge'
  gem 'rails', git: 'https://github.com/rails/rails.git'
else
  gem 'rails', "~> #{ENV['RAILS_VERSION'] || '7.2'}.0"
end

gem 'rake'
gem 'rspec-rails'

gem 'rubocop', require: false
gem 'rubocop-performance', require: false
gem 'rubocop-rails', require: false
gem 'rubocop-rspec', require: false

gem 'smtp_mock'

gem 'sqlite3', '~> 2.1'
