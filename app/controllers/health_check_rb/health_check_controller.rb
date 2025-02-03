# frozen_string_literal: true

require 'ipaddr'

module HealthCheckRb
  class HealthCheckController < ActionController::Base
    layout false if respond_to? :layout
    before_action :check_origin_ip
    before_action :authenticate

    def index
      last_modified = Time.now.utc
      max_age = HealthCheckRb.max_age
      last_modified = Time.at((last_modified.to_f / max_age).floor * max_age).utc if max_age > 1
      is_public = (max_age > 1) && !HealthCheckRb.basic_auth_username
      return unless stale? last_modified: last_modified, public: is_public

      checks = params[:checks] ? params[:checks].split('_') : ['standard']
      checks -= HealthCheckRb.middleware_checks if HealthCheckRb.installed_as_middleware
      begin
        errors = HealthCheckRb::Utils.process_checks checks
      rescue StandardError => e
        errors = e.message.blank? ? e.class.to_s : e.message.to_s
      end
      response.headers['Cache-Control'] = "must-revalidate, max-age=#{max_age}"
      if errors.blank?
        send_response true, nil, :ok, :ok
        HealthCheckRb.success_callbacks&.each do |callback|
          callback.call checks
        end
      else
        msg = HealthCheckRb.include_error_in_response_body ? "#{HealthCheckRb.failure}: #{errors}" : nil
        send_response false, msg, HealthCheckRb.http_status_for_error_text, HealthCheckRb.http_status_for_error_object

        # Log a single line as some uptime checkers only record that it failed, not the text returned
        msg = "#{HealthCheckRb.failure}: #{errors}"
        logger.send HealthCheckRb.log_level, msg if logger && HealthCheckRb.log_level
        HealthCheckRb.failure_callbacks&.each do |callback|
          callback.call checks, msg
        end
      end
    end

    protected

    def send_response(healthy, msg, text_status, obj_status)
      msg ||= healthy ? HealthCheckRb.success : HealthCheckRb.failure
      obj = { healthy: healthy, message: msg }
      respond_to do |format|
        format.html { render plain: msg, status: text_status, content_type: 'text/plain' }
        format.json { render json: obj, status: obj_status }
        format.xml { render xml: obj, status: obj_status }
        format.any { render plain: msg, status: text_status, content_type: 'text/plain' }
      end
    end

    def authenticate
      return unless HealthCheckRb.basic_auth_username && HealthCheckRb.basic_auth_password

      authenticate_or_request_with_http_basic 'Health Check' do |username, password|
        username == HealthCheckRb.basic_auth_username && password == HealthCheckRb.basic_auth_password
      end
    end

    def check_origin_ip
      request_ipaddr = IPAddr.new(HealthCheckRb.accept_proxied_requests ? request.remote_ip : request.ip)
      unless HealthCheckRb.origin_ip_whitelist.blank? ||
             HealthCheckRb.origin_ip_whitelist.any? { |addr| IPAddr.new(addr).include? request_ipaddr }
        render plain: 'Health check is not allowed for the requesting IP',
               status: HealthCheckRb.http_status_for_ip_whitelist_error,
               content_type: 'text/plain'
      end
    end

    # turn cookies for CSRF off
    def protect_against_forgery?
      false
    end
  end
end
