# frozen_string_literal: true

module HealthCheck
  class ResqueHealthCheck
    extend BaseHealthCheck

    def self.check
      raise "Wrong configuration. Missing 'resque' gem" unless defined?(::Resque)

      res = ::Resque.redis.ping
      res == 'PONG' ? '' : "Resque.redis.ping returned #{res.inspect} instead of PONG"
    rescue StandardError => e
      create_error 'resque-redis', e.message
    end
  end
end
