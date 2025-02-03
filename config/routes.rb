# frozen_string_literal: true

unless HealthCheckRb::Engine.routes_explicitly_defined
  Rails.application.routes.draw do
    add_health_check_rb_routes
  end
end
