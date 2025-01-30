# frozen_string_literal: true

module HealthCheck
  class SidekiqHealthCheck
    extend BaseHealthCheck

    def self.check
      raise "Wrong configuration. Missing 'sidekiq' gem" unless defined?(::Sidekiq)

      ::Sidekiq.redis do |r|
        res = r.ping
        res == 'PONG' ? '' : "Sidekiq.redis.ping returned #{res.inspect} instead of PONG"
      end
    rescue StandardError => e
      create_error 'sidekiq-redis', e.message
    end
  end
end
