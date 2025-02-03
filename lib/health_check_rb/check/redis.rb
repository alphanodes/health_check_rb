# frozen_string_literal: true

module HealthCheckRb
  module Check
    class Redis
      extend BaseHealthCheck

      class << self
        def check
          raise "Wrong configuration. Missing 'redis' gem" unless defined?(::Redis)

          client.ping == 'PONG' ? '' : "Redis.ping returned #{res.inspect} instead of PONG"
        rescue StandardError => e
          create_error 'redis', e.message
        ensure
          client.close if client.connected?
        end

        def client
          @client ||= Redis.new(
            {
              url: HealthCheckRb.redis_url,
              username: HealthCheckRb.redis_username,
              password: HealthCheckRb.redis_password
            }.compact
          )
        end
      end
    end
  end
end
