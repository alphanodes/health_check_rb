# frozen_string_literal: true

module HealthCheckRb
  module Check
    class Resque
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
end
