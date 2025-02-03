# frozen_string_literal: true

module HealthCheckRb
  module Check
    class Redis
      extend BaseHealthCheck

      class << self
        def check
          client.call('PING') == 'PONG' ? '' : "ping returned #{res.inspect} instead of PONG"
        rescue StandardError => e
          create_error 'redis', e.message
        ensure
          client.close if client.connected?
        end

        def client
          @client ||= if defined?(::Redis)
                        Redis.new redis_config
                      elsif defined?(::RedisClient)
                        RedisClient.new redis_config
                      else
                        raise "Wrong configuration. Missing 'redis' or 'redis-client' gem"
                      end
        end

        def redis_config
          {
            url: HealthCheckRb.redis_url,
            username: HealthCheckRb.redis_username,
            password: HealthCheckRb.redis_password
          }.compact
        end
      end
    end
  end
end
