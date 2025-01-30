# frozen_string_literal: true

require_relative 'dummy/fake_app'
require 'rspec/rails'
require 'fake_smtp_server'

def start_smtp_server(&)
  th = Thread.start do
    server = FakeSmtpServer.new 3555
    server.start
    server.finish
  end
  sleep 1
  yield
  socket = TCPSocket.open 'localhost', 3555
  socket.write 'QUIT'
  socket.close
  th.join
end

def enable_custom_check(&)
  File.write CUSTOM_CHECK_FILE_PATH, 'hello'
  yield
ensure
  FileUtils.rm CUSTOM_CHECK_FILE_PATH if File.exist? CUSTOM_CHECK_FILE_PATH
end

def disconnect_database
  if Gem::Version.new(Rails.version) >= Gem::Version.new('7.1.0')
    ActiveRecord::Tasks::DatabaseTasks.migration_connection.disconnect!
  else
    ActiveRecord::Base.connection.disconnect!
  end
end

def reconnect_database
  if Gem::Version.new(Rails.version) >= Gem::Version.new('7.1.0')
    ActiveRecord::Tasks::DatabaseTasks.migration_connection.reconnect!
  else
    ActiveRecord::Base.establish_connection
  end
end

def db_migrate
  system 'RAILS_ENV=test bundle exec rake db:migrate'
end
