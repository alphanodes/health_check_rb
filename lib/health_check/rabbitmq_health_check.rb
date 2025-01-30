# frozen_string_literal: true

module HealthCheck
  class RabbitMQHealthCheck
    extend BaseHealthCheck
    def self.check
      raise "Wrong configuration. Missing 'bunny' gem" unless defined?(::Bunny)

      connection = Bunny.new HealthCheck.rabbitmq_config
      connection.start
      connection.close
      ''
    rescue Exception => e
      create_error 'rabbitmq', e.message
    end
  end
end
