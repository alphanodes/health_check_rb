# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      def health_check_rb_routes(prefix = nil)
        HealthCheckRb::Engine.routes_explicitly_defined = true
        add_health_check_rb_routes prefix
      end

      def add_health_check_rb_routes(prefix = nil)
        HealthCheckRb.uri = prefix if prefix
        match "#{HealthCheckRb.uri}(/:checks)(.:format)", controller: 'health_check_rb/health_check', action: :index, via: %i[get post],
                                                          defaults: { format: 'txt' }
      end
    end
  end
end
