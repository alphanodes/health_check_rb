# frozen_string_literal: true

module HealthCheckRb
  module Check
    class RabbitMQ
      extend BaseHealthCheck

      def self.check
        raise "Wrong configuration. Missing 'bunny' gem" unless defined?(::Bunny)

        connection = Bunny.new HealthCheckRb.rabbitmq_config
        connection.start
        connection.close
        ''
      rescue StandardError => e
        create_error 'rabbitmq', e.message
      end
    end
  end
end
