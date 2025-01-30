# frozen_string_literal: true

module HealthCheck
  class ElasticsearchHealthCheck
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
