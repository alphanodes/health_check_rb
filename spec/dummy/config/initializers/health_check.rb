# frozen_string_literal: true

CUSTOM_CHECK_FILE_PATH = 'spec/dummy/tmp/custom_file'

HealthCheck.setup do |config|
  config.success = 'custom_success_message'
  config.http_status_for_error_text = 550
  config.http_status_for_error_object = 555
  config.uri = 'custom_route_prefix'

  config.add_custom_check do
    File.exist?(CUSTOM_CHECK_FILE_PATH) ? '' : 'custom_file is missing!'
  end

  config.add_custom_check 'pass' do
    ''
  end
end
