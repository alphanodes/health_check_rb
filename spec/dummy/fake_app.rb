# frozen_string_literal: true

Bundler.setup
require 'rails'
require 'rails/all'
require 'health_check'
Bundler.require

FakeApp = Class.new Rails::Application
ENV['RAILS_ENV'] ||= 'test'
FakeApp.config.eager_load = false
FakeApp.config.session_store :cookie_store, key: '_myapp_session'
FakeApp.config.root = File.dirname __FILE__
FakeApp.config.action_mailer.delivery_method = :smtp
FakeApp.config.action_mailer.smtp_settings = { address: 'localhost', port: 3555, openssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
                                               enable_starttls_auto: true }
FakeApp.config.secret_key_base = SecureRandom.hex 64
FakeApp.initialize!
