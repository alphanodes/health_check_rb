# frozen_string_literal: true

lib = File.expand_path 'lib', __dir__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require 'health_check/version'

Gem::Specification.new do |gem|
  gem.name          = 'health_check'
  gem.version       = HealthCheck::VERSION
  gem.required_rubygems_version = Gem::Requirement.new('>= 0') if gem.respond_to? :required_rubygems_version=
  gem.authors       = ['Ian Heggie']
  gem.email         = ['ian@heggie.biz']
  gem.summary = 'Simple health check of Rails app for uptime monitoring with Pingdom, NewRelic, EngineYard etc.'
  gem.description = <<-EOF
  	Simple health check of Rails app for uptime monitoring with Pingdom, NewRelic, EngineYard etc.
  EOF
  gem.homepage      = 'https://github.com/ianheggie/health_check'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split $/
  gem.extra_rdoc_files = ['README.rdoc']
  gem.require_paths = ['lib']
  gem.required_ruby_version = '>= 3.1'
  gem.add_dependency 'railties', ['>= 5.0']
  gem.metadata['rubygems_mfa_required'] = 'true'
end
