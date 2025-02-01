# frozen_string_literal: true

require_relative 'dummy/fake_app'
require 'rspec/rails'
require 'smtp_mock/test_framework/rspec'

RSpec.configure do |config|
  config.include SmtpMock::TestFramework::RSpec::Helper
end

# see https://github.com/mocktools/ruby-smtp-mock
def mock_smtp_server(&)
  smtp_mock_server port: 3555 do
    sleep 1
    yield
  end
end

def enable_custom_check(&)
  File.write CUSTOM_CHECK_FILE_PATH, 'hello'
  yield
ensure
  FileUtils.rm CUSTOM_CHECK_FILE_PATH if File.exist? CUSTOM_CHECK_FILE_PATH
end

def disconnect_database
  ActiveRecord::Tasks::DatabaseTasks.migration_connection.disconnect!
end

def reconnect_database
  ActiveRecord::Tasks::DatabaseTasks.migration_connection.reconnect!
end

def db_migrate
  system 'RAILS_ENV=test bundle exec rake db:migrate'
end
