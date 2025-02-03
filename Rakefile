# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec

task default: :spec

begin
  gem 'rdoc'
  require 'rdoc/task'

  Rake::RDocTask.new do |rdoc|
    version = HealthCheckRb::VERSION

    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "health_check_rb #{version}"
    rdoc.rdoc_files.include 'README*'
    rdoc.rdoc_files.include 'CHANGELOG'
    rdoc.rdoc_files.include 'MIT-LICENSE'
    rdoc.rdoc_files.include 'lib/**/*.rb'
  end
rescue Gem::LoadError
  puts 'rdoc (or a dependency) not available. Install it with: gem install rdoc'
end
