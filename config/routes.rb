# frozen_string_literal: true

unless HealthCheck::Engine.routes_explicitly_defined
  Rails.application.routes.draw do
    add_health_check_routes
  end
end
