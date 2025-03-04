# frozen_string_literal: true

require 'ipaddr'

module HealthCheckRb
  class MiddlewareHealthcheck
    def initialize(app)
      @app = app
    end

    def call(env)
      (response_type, middleware_checks, full_stack_checks) = parse_env env
      if response_type
        if (error_response = ip_blocked(env) || not_authenticated(env))
          return error_response
        end

        HealthCheckRb.installed_as_middleware = true
        errors = ''
        begin
          # Process the checks to be run from middleware
          errors = HealthCheckRb::Utils.process_checks middleware_checks,
                                                       called_from_middleware: true
          # Process remaining checks through the full stack if there are any
          return @app.call env unless full_stack_checks.empty?
        rescue StandardError => e
          errors = e.message.blank? ? e.class.to_s : e.message.to_s
        end
        healthy = errors.blank?
        msg = healthy ? HealthCheckRb.success : "health_check failed: #{errors}"
        if response_type == 'xml'
          content_type = 'text/xml'
          msg = { healthy: healthy, message: msg }.to_xml
          error_code = HealthCheckRb.http_status_for_error_object
        elsif response_type == 'json'
          content_type = 'application/json'
          msg = { healthy: healthy, message: msg }.to_json
          error_code = HealthCheckRb.http_status_for_error_object
        else
          content_type = 'text/plain'
          error_code = HealthCheckRb.http_status_for_error_text
        end
        [(healthy ? 200 : error_code), { 'Content-Type' => content_type }, [msg]]
      else
        @app.call env
      end
    end

    protected

    def parse_env(env)
      uri = env['PATH_INFO']
      return unless uri =~ %r{^/#{Regexp.escape HealthCheckRb.uri}(/([-_0-9a-zA-Z]*))?(\.(\w*))?$}

      checks = ::Regexp.last_match(2).to_s == '' ? ['standard'] : ::Regexp.last_match(2).split('_')
      response_type = ::Regexp.last_match(4).to_s
      middleware_checks = checks & HealthCheckRb.middleware_checks
      full_stack_checks = (checks - HealthCheckRb.middleware_checks) - ['and']
      [response_type, middleware_checks, full_stack_checks]
    end

    def ip_blocked(env)
      return false if HealthCheckRb.origin_ip_whitelist.blank?

      req = Rack::Request.new env
      request_ipaddr = IPAddr.new req.ip
      return if HealthCheckRb.origin_ip_whitelist.any? { |addr| IPAddr.new(addr).include? request_ipaddr }

      [HealthCheckRb.http_status_for_ip_whitelist_error,
       { 'Content-Type' => 'text/plain' },
       ['Health check is not allowed for the requesting IP']]
    end

    def not_authenticated(env)
      return false unless HealthCheckRb.basic_auth_username && HealthCheckRb.basic_auth_password

      auth = MiddlewareHealthcheck::Request.new env
      if auth.provided? && auth.basic? && Rack::Utils.secure_compare(HealthCheckRb.basic_auth_username,
                                                                     auth.username) && Rack::Utils.secure_compare(
                                                                       HealthCheckRb.basic_auth_password, auth.password
                                                                     )
        env['REMOTE_USER'] = auth.username
        return false
      end
      [401,
       { 'Content-Type' => 'text/plain', 'WWW-Authenticate' => 'Basic realm="Health Check"' },
       []]
    end

    class Request < Rack::Auth::AbstractRequest
      def basic?
        scheme == 'basic'
      end

      def credentials
        @credentials ||= params.unpack1('m*').split(':', 2)
      end

      def username
        credentials.first
      end

      def password
        credentials.last
      end
    end
  end
end
