# frozen_string_literal: true

FakeApp.config.middleware.insert_after Rails::Rack::Logger, HealthCheck::MiddlewareHealthcheck if ENV['MIDDLEWARE'] == 'true'
