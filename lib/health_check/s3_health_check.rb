# frozen_string_literal: true

module HealthCheck
  class S3HealthCheck
    extend BaseHealthCheck

    class << self
      def check
        raise "Wrong configuration. Missing 'aws-sdk' or 'aws-sdk-s3' gem" unless defined?(::Aws)
        return create_error 's3', 'Could not connect to aws' if aws_s3_client.nil?

        HealthCheck.buckets.each do |bucket_name, permissions|
          permissions = %i[R W D] if permissions.nil? # backward compatible
          permissions.each do |permision|
            send permision, bucket_name
          rescue StandardError => e
            raise "bucket:#{bucket_name}, permission:#{permision} - #{e.message}"
          end
        end
        ''
      rescue StandardError => e
        create_error 's3', e.message
      end

      private

      # We already assume you are using Rails.  Let's also assume you have an initializer
      # created for your Aws config.  We will set the region here so you can use an
      # instance profile and simply set the region in your environment.
      def configure_client
        ::Aws.config[:s3] = { force_path_style: true }
        ::Aws.config[:region] ||= ENV['AWS_REGION'] || ENV.fetch('DEFAULT_AWS_REGION', nil)

        ::Aws::S3::Client.new
      end

      def aws_s3_client
        @aws_s3_client ||= configure_client
      end

      def R(bucket)
        aws_s3_client.list_objects bucket: bucket
      end

      def W(bucket)
        app_name = if Rails::VERSION::MAJOR >= 6
                     ::Rails.application.class.module_parent_name
                   else
                     ::Rails.application.class.parent_name
                   end

        aws_s3_client.put_object(bucket: bucket,
                                 key: "healthcheck_#{app_name}",
                                 body: Time.new.to_s)
      end

      def D(bucket)
        app_name = if Rails::VERSION::MAJOR >= 6
                     ::Rails.application.class.module_parent_name
                   else
                     ::Rails.application.class.parent_name
                   end
        aws_s3_client.delete_object(bucket: bucket,
                                    key: "healthcheck_#{app_name}")
      end
    end
  end
end
