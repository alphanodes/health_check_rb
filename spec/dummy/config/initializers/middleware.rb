# frozen_string_literal: true

FakeApp.config.middleware.insert_after Rails::Rack::Logger, HealthCheckRb::MiddlewareHealthcheck if ENV['MIDDLEWARE'] == 'true'
