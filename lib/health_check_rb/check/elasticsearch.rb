# frozen_string_literal: true

module HealthCheckRb
  module Check
    class Elasticsearch
      extend BaseHealthCheck

      def self.check
        raise "Wrong configuration. Missing 'elasticsearch' gem" unless defined?(::Elasticsearch)

        res = ::Elasticsearch::Client.new.ping
        res == true ? '' : "Elasticsearch returned #{res.inspect} instead of true"
      rescue StandardError => e
        create_error 'elasticsearch', e.message
      end
    end
  end
end
