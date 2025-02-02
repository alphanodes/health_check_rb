# frozen_string_literal: true

# Copyright (c) 2010-2013 Ian Heggie, released under the MIT license.
# See MIT-LICENSE for details.

module HealthCheck
  class Utils
    # TODO: convert class variables to better solution
    # rubocop: disable Style/ClassVars
    @@default_smtp_settings =
      {
        address: 'localhost',
        port: 25,
        domain: 'localhost.localdomain',
        user_name: nil,
        password: nil,
        authentication: nil,
        enable_starttls_auto: true
      }
    # rubocop: enable Style/ClassVars

    cattr_writer :db_migrate_path
    cattr_accessor :default_smtp_settings

    class << self
      # process an array containing a list of checks
      def process_checks(checks, called_from_middleware: false)
        errors = +''
        checks.each do |check|
          case check
          when 'and', 'site'
          # do nothing
          when 'database'
            HealthCheck::Utils.database_version
          when 'email'
            errors << HealthCheck::Utils.check_email
          when 'emailconf'
            errors << HealthCheck::Utils.check_email if HealthCheck::Utils.mailer_configured?
          when 'migrations', 'migration'
            if defined?(ActiveRecord::Migration) && ActiveRecord::Migration.respond_to?(:check_all_pending!)
              # Rails 7.2+
              begin
                ActiveRecord::Migration.check_all_pending!
              rescue ActiveRecord::PendingMigrationError => e
                errors << e.message
              end
            else
              database_version  = HealthCheck::Utils.database_version
              migration_version = HealthCheck::Utils.migration_version
              if database_version.to_i != migration_version.to_i
                errors << "Current database version (#{database_version}) does not match latest migration (#{migration_version}). "
              end
            end
          when 'cache'
            errors << HealthCheck::Utils.check_cache
          when 'resque-redis-if-present'
            errors << HealthCheck::ResqueHealthCheck.check if defined?(::Resque)
          when 'sidekiq-redis-if-present'
            errors << HealthCheck::SidekiqHealthCheck.check if defined?(::Sidekiq)
          when 'redis-if-present'
            errors << HealthCheck::RedisHealthCheck.check if defined?(::Redis)
          when 's3-if-present'
            errors << HealthCheck::S3HealthCheck.check if defined?(::Aws)
          when 'elasticsearch-if-present'
            errors << HealthCheck::ElasticsearchHealthCheck.check if defined?(::Elasticsearch)
          when 'resque-redis'
            errors << HealthCheck::ResqueHealthCheck.check
          when 'sidekiq-redis'
            errors << HealthCheck::SidekiqHealthCheck.check
          when 'redis'
            errors << HealthCheck::RedisHealthCheck.check
          when 's3'
            errors << HealthCheck::S3HealthCheck.check
          when 'elasticsearch'
            errors << HealthCheck::ElasticsearchHealthCheck.check
          when 'rabbitmq'
            errors << HealthCheck::RabbitMQHealthCheck.check
          when 'standard'
            errors << HealthCheck::Utils.process_checks(HealthCheck.standard_checks, called_from_middleware:)
          when 'middleware'
            errors << 'Health check not called from middleware - probably not installed as middleware.' unless called_from_middleware
          when 'custom'
            HealthCheck.custom_checks.each_value do |list|
              list.each do |custom_check|
                errors << custom_check.call(self)
              end
            end
          when 'all', 'full'
            errors << HealthCheck::Utils.process_checks(HealthCheck.full_checks, called_from_middleware:)
          else
            return 'invalid argument to health_test.' unless HealthCheck.custom_checks.include? check

            HealthCheck.custom_checks[check].each do |custom_check|
              errors << custom_check.call(self)
            end

          end
          errors << '. ' unless errors == '' || errors.end_with?('. ')
        end
        errors.strip
      rescue StandardError => e
        e.message
      end

      def db_migrate_path
        # Lazy initialisation so Rails.root will be defined
        @db_migrate_path ||= Rails.root.join 'db', 'migrate'.to_s
      end

      def mailer_configured?
        defined?(ActionMailer::Base) &&
          (ActionMailer::Base.delivery_method != :smtp || HealthCheck::Utils.default_smtp_settings != ActionMailer::Base.smtp_settings)
      end

      def database_version
        ActiveRecord::Migrator.current_version if defined?(ActiveRecord)
      end

      def migration_version(dir = db_migrate_path)
        latest_migration = nil
        Dir[File.join(dir, '[0-9]*_*.rb')].each do |f|
          l = begin
            f.scan(/0*([0-9]+)_[_.a-zA-Z0-9]*.rb/).first.first
          rescue StandardError
            -1
          end
          latest_migration = l if !latest_migration || l.to_i > latest_migration.to_i
        end
        latest_migration
      end

      def check_email
        case ActionMailer::Base.delivery_method
        when :smtp
          HealthCheck::Utils.check_smtp(ActionMailer::Base.smtp_settings, HealthCheck.smtp_timeout)
        when :sendmail
          HealthCheck::Utils.check_sendmail(ActionMailer::Base.sendmail_settings)
        else
          ''
        end
      end

      def check_sendmail(settings)
        File.executable?(settings[:location]) ? '' : 'no sendmail executable found. '
      end

      def check_smtp(settings, timeout)
        begin
          if @skip_external_checks
            status = '250'
          else
            smtp = Net::SMTP.new settings[:address], settings[:port]
            openssl_verify_mode = settings[:openssl_verify_mode]

            openssl_verify_mode = OpenSSL::SSL.const_get("VERIFY_#{openssl_verify_mode.upcase}") if openssl_verify_mode.is_a? String

            ssl_context = Net::SMTP.default_ssl_context
            ssl_context.verify_mode = openssl_verify_mode if openssl_verify_mode
            smtp.enable_starttls ssl_context if settings[:enable_starttls_auto]
            smtp.open_timeout = timeout
            smtp.read_timeout = timeout
            smtp.start settings[:domain], settings[:user_name], settings[:password], settings[:authentication] do
              status = smtp.helo(settings[:domain]).status
            end
          end
        rescue StandardError => e
          status = e.to_s
        end
        /^250/.match?(status) ? '' : "SMTP: #{status || 'unexpected error'}. "
      end

      def check_cache
        t = Time.now.to_i
        value = "ok #{t}"
        ret = ::Rails.cache.read '__health_check_cache_test__'
        if ret.to_s =~ /^ok (\d+)$/
          diff = (::Regexp.last_match(1).to_i - t).abs
          return('Cache expiry is broken. ') if diff > 30
        elsif ret
          return 'Cache is returning garbage. '
        end
        if ::Rails.cache.write '__health_check_cache_test__', value, expires_in: 2.seconds
          ret = ::Rails.cache.read '__health_check_cache_test__'
          if ret =~ /^ok (\d+)$/
            diff = (::Regexp.last_match(1).to_i - t).abs
            (diff < 2 ? '' : 'Out of date cache or time is skewed. ')
          else
            'Unable to read from cache. '
          end
        else
          'Unable to write to cache. '
        end
      end
    end
  end
end
