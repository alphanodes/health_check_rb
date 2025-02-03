# health_check_rb gem

[![Tests](https://github.com/AlphaNodes/health_check_rb/workflows/Tests/badge.svg)](https://github.com/alphanodes/health_check_rb/actions/workflows/tests.yml) [![Run Linters](https://github.com/alphanodes/health_check_rb/workflows/Run%20Linters/badge.svg)](https://github.com/alphanodes/health_check_rb/actions/workflows/linters.yml)

Simple health check of Rails apps for use with Pingdom, NewRelic, EngineYard etc.

This is a fork of <https://github.com/Purple-Devs/health_check>

The basic goal is to quickly check that rails is up and running and that it has access to correctly configured resources (database, email gateway)

health_check provides various monitoring URIs, for example:

```shell
curl localhost:3000/health_check
```

```text
success
```

```shell
curl localhost:3000/health_check/all.json
```

```json
{ "healthy": true, "message": "success" }
```

```shell
curl localhost:3000/health_check/database_cache_migration.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<hash>
  <healthy type="boolean">true</healthy>
  <message>success</message>
</hash>
```

You may also issue POST calls instead of GET to these urls.

On failure (detected by health_check) a 500 http status is returned with a simple explanation of the failure (if include_error_in_response_body is true)

```shell
curl localhost:3000/health_check/fail
```

```text
health_check failed: invalid argument to health_test.
```

The health_check controller disables sessions for versions that eagerly load sessions.

## Supported Versions

* Ruby 3.1, 3.2, 3.3, 3.4
* Rails 7.2, 8.0

## Checks

* standard (default) - site, database and migrations checks are run plus email if ActionMailer is defined and it is not using the default configuration
* all / full - all checks are run (can be overridden in config block)
* cache - checks that a value can be written to the cache
* custom - runs checks added via config.add_custom_check
* database - checks that the current migration level can be read from the database
* email - basic check of email - :test returns true, :sendmail checks file is present and  executable, :smtp sends HELO command to server and checks response
* migration - checks that the database migration level matches that in db/migrations
* rabbitmq - RabbitMQ Health Check
* redis / redis-if-present - checks Redis connectivity
* resque-redis / resque-redis-if-present - checks Resque connectivity to Redis
* s3 / s3-if-present - checks proper permissions to s3 buckets
* sidekiq-redis / sidekiq-redis-if-present - checks Sidekiq connectivity to Redis
* elasticsearch / elasticsearch-if-present - checks Elasticsearch connectivity
* site - checks rails is running sufficiently to render text

Some checks have a *-if-present form, which only runs the check if the corresponding library has been required.

The email gateway is not checked unless the smtp settings have been changed.
Specify full or include email in the list of checks to verify the smtp settings
(eg use 127.0.0.1 instead of localhost).

Note: rails also checks migrations by default in development mode and throws an `ActiveRecord::PendingMigrationError` exception (http error 500) if there is an error

## Installation

Add the following line to Gemfile (after the rails gems are listed)

```ruby
gem 'health_check_rb'
```

And then execute

```shell
bundle install
```

## Configuration

To change the configuration of health_check, create a file `config/initializers/health_check_rb.rb` and add a configuration block like:

```ruby
HealthCheckRb.setup do |config|

  # uri prefix (no leading slash)
  config.uri = 'health_check'

  # Text output upon success
  config.success = 'success'

  # Text output upon failure
  config.failure = 'health_check failed'

  # Disable the error message to prevent /health_check from leaking
  # sensitive information
  config.include_error_in_response_body = false

  # Log level (success or failure message with error details is sent to rails log unless this is set to nil)
  config.log_level = 'info'

  # Timeout in seconds used when checking smtp server
  config.smtp_timeout = 30.0

  # http status code used when plain text error message is output
  # Set to 200 if you want your want to distinguish between partial (text does not include success) and
  # total failure of rails application (http status of 500 etc)

  config.http_status_for_error_text = 500

  # http status code used when an error object is output (json or xml)
  # Set to 200 if you want to distinguish between partial (healthy property == false) and
  # total failure of rails application (http status of 500 etc)

  config.http_status_for_error_object = 500

  # bucket names to test connectivity - required only if s3 check used, access permissions can be mixed
  config.buckets = {'bucket_name' => [:R, :W, :D]}

  # You can customize which checks happen on a standard health check, eg to set an explicit list use:
  config.standard_checks = [ 'database', 'migrations', 'custom' ]

  # Or to exclude one check:
  config.standard_checks -= [ 'emailconf' ]

  # You can set what tests are run with the 'full' or 'all' parameter
  config.full_checks = ['database', 'migrations', 'custom', 'email', 'cache', 'redis', 'resque-redis', 'sidekiq-redis', 's3']

  # Add one or more custom checks that return a blank string if ok, or an error message if there is an error
  config.add_custom_check do
    CustomHealthCheck.perform_check # any code that returns blank on success and non blank string upon failure
  end

  # Add another custom check with a name, so you can call just specific custom checks. This can also be run using
  # the standard 'custom' check.
  # You can define multiple tests under the same name - they will be run one after the other.
  config.add_custom_check('sometest') do
    CustomHealthCheck.perform_another_check # any code that returns blank on success and non blank string upon failure
  end

  # max-age of response in seconds
  # cache-control is public when max_age > 1 and basic_auth_username is not set
  # You can force private without authentication for longer max_age by
  # setting basic_auth_username but not basic_auth_password
  config.max_age = 1

  # Protect health endpoints with basic auth
  # These default to nil and the endpoint is not protected
  config.basic_auth_username = 'my_username'
  config.basic_auth_password = 'my_password'

  # Whitelist requesting IPs by a list of IP and/or CIDR ranges, either IPv4 or IPv6 (uses IPAddr.include? method to check)
  # Defaults to blank which allows any IP
  config.origin_ip_whitelist = %w(123.123.123.123 10.11.12.0/24 2400:cb00::/32)

  # Use ActionDispatch::Request's remote_ip method when behind a proxy to pick up the real remote IP for origin_ip_whitelist check
  # Otherwise uses Rack::Request's ip method (the default, and always used by Middleware), which is more susceptible to spoofing
  # See https://stackoverflow.com/questions/10997005/whats-the-difference-between-request-remote-ip-and-request-ip-in-rails
  config.accept_proxied_requests = false

  # http status code used when the ip is not allowed for the request
  config.http_status_for_ip_whitelist_error = 403

  # rabbitmq
  config.rabbitmq_config = {}

  # When redis url/password is non-standard
  config.redis_url = 'redis_url' # default ENV['REDIS_URL']
  # Only use if set, as url can optionally include username as well
  config.redis_username = 'redis_username' # default ENV['REDIS_USERNAME']
  # Only included if set, as url can optionally include passwords as well
  config.redis_password = 'redis_password' # default ENV['REDIS_PASSWORD']

  # Failure Hooks to do something more ...
  # checks lists the checks requested
  config.on_failure do |checks, msg|
    # log msg somewhere
  end

  config.on_success do |checks|
    # flag that everything is well
  end
end
```

You may call add_custom_check multiple times with different tests. These tests will be included in the default list ("standard").

If you have a catchall route then add the following line above the catch all route (in `config/routes.rb`):

```ruby
health_check_rb_routes
```

### Installing As Middleware

Install health_check as middleware if you want to sometimes ignore exceptions from later parts of the Rails middleware stack, eg DB connection errors from QueryCache. The "middleware" check will fail if you have not installed health_check as middleware.

To install health_check as middleware add the following line to the config/application.rb:

```ruby
config.middleware.insert_after Rails::Rack::Logger, HealthCheckRb::MiddlewareHealthcheck
```

Note: health_check is installed as a full rails engine even if it has been installed as middleware. This is so the remaining checks continue to run through the complete rails stack.

You can also adjust what checks are run from middleware, eg if you want to exclude the checking of the database etc, then set

```ruby
config.middleware_checks = ['middleware', 'standard', 'custom']
config.standard_checks = ['middleware', 'custom']
```

Middleware checks are run first, and then full stack checks.
When installed as middleware, exceptions thrown when running the full stack tests are formatted in the standard way.

## Uptime Monitoring

Use a website monitoring service to check the url regularly for the word "success" (without the quotes) rather than just a 200 http status so
that any substitution of a different server or generic information page should also be reported as an error.

If an error is encountered, the text "health_check failed: some error message/s" will be returned and the http status will be 500.

See

* Pingdom Website Monitoring - <https://www.pingdom.com/>
* NewRelic Availability Monitoring - <https://newrelic.com/>
* Engine Yard's guide - <https://support.engineyard.com/hc/en-us/articles/7598752539282-Monitor-Application-Uptime> (although the guide is based on fitter_happier plugin it will also work with this gem)
* Nagios check_http (with -s success) - <https://nagios-plugins.org/doc/man/check_http.html>
* Any other montoring service that can be set to check for the word success in the text returned from a url

### Requesting Json and XML responses

Health_check will respond with an encoded hash object if json or xml is requested.
Either set the HTTP Accept header or append .json or .xml to the url.

The hash contains two keys:

* healthy - true if requested checks pass (boolean)
* message - text message ("success" or error message)

The following commands

```shell
curl -v localhost:3000/health_check.json
curl -v localhost:3000/health_check/email.json
curl -v -H "Accept: application/json" localhost:3000/health_check
```

Will return a result with Content-Type: application/json and body like:

```json
{ "healthy": true, "message": "success" }
```

These following commands

```shell
curl -v localhost:3000/health_check.xml
curl -v localhost:3000/health_check/migration_cache.xml
curl -v -H "Accept: text/xml" localhost:3000/health_check/cache
```

Will return a result with Content-Type: application/xml and body like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<hash>
  <healthy type="boolean">true</healthy>
  <message>success</message>
</hash>
```

See <https://github.com/ianheggie/health_check/wiki/Ajax-Example> for an Ajax example

## Silencing log output

It is recommended that you use silencer, lograge or one of the other log filtering gems.

For example, with lograge use the following to exclude health_check from being logged:

```ruby
config.lograge.ignore_actions = ["HealthCheckRb::HealthCheckController#index"]
```

Likewise you will probably want to exclude health_check from monitoring systems like newrelic.

## Caching

Cache-control is set with

* public if max_age is > 1 and basic_auth_username is not set (otherwise private)
* no-cache
* must-revalidate
* max-age (default 1)

Last-modified is set to the current time (rounded down to a multiple of max_age when max_age > 1)

## Known Issues

* See <https://github.com/alphanodes/health_check_rb/issues>

## Similar projects

* health_check by Ian Heggie - this plugin is a fork of it
* fitter_happier plugin by atmos - plugin with similar goals, but not compatible with uptime, and does not check email gateway
* HealthBit - inspired by this gem but with a fresh start as a simpler rack only application, no travis CI tests (yet?) but looks interesting.

## Manual testing

You can run the tests locally as follows:

```shell
# install gem packages
bundle install
# install smtp_mock for e-mail tests
bundle exec smtp_mock -i ~
# run tests
bundle exec rake
```

## Copyright

Copyright (c) 2025 Alexander Meindl, released under the MIT license.
Copyright (c) 2010-2021 Ian Heggie, released under the MIT license.
See MIT-LICENSE for details.

## Contributors

Thanks go to the various people who have given feedback and suggestions via the issues list and pull requests.

### Contributing

Feedback welcome! Especially with suggested replacement code, tests and documentation
