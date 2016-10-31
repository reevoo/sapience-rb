## v2.0.1

- Add metrics for model actions (create, update, destroy)

## v2.0.0

- Prevent Raven from recursively capturing its own exceptions
- Make logger interface explicit (no metaprogramming)
- Separate error handling and metrics from appenders
- Added `Sapience.capture_exception` and `Sapience.capture_message` methods
- Added `logger.error!` and `logger.fatal!` that also sends any exception to the configured error handler

## v1.0.14

- Reduce log output noise from the sentry logger

## v1.0.13

- Fix a problem with logging extra parameters to sentry

## v1.0.12

- Fix NoMethodError in Grape::Notification
- Exclude test apps from Gem

## v1.0.11

- Fix a NoMethodError with logging the response format in grape

## v1.0.10

- Automatically add default `datadog` appender when calling `Sapience.metrics` 

## v1.0.9

- Added `filter_parameters` configuration to obfuscate sensitive information such as passwords for rack-like applications
- Require Grape version >= 0.16.2, raise if lesser version is found

## v1.0.8

- Delayed configuration of Sentry until the configuration is valid

## v1.0.3

- Rename `SAPIENCE_APP_NAME` to `APP_NAME`
- Allow for configuration inheritance (see the history for [config_loader.rb](https://github.com/reevoo/sapience-rb/blame/master/lib/sapience/config_loader.rb#L19))

## v1.0.2

- Require `app_name` to be configured. Either set it with the environment variable `SAPIENCE_APP_NAME` or provided it when configuring the application.
- Fixes problems with Datadog namespace always being nil.

## v1.0.1

- Fix loading configuration outside of Rack application

## v1.0.0

- Rename Sapience.metrix to Sapience.metrics

## v0.2.17

- Update datadog appender to use Datadog::Statsd from dogstatsd-ruby gem

## v0.2.15

- Fix issue with not resetting previously attached appenders when calling `Sapience.configure`.

## v0.2.14

- Reduce noise for assets:precompile by changing default Railtie log level to :warn instead of :debug

## v0.2.13

- Set Rails.logger even some gems disables logging on initialisation.

## v0.2.12

- Adds support for Rails apps with disabled ActiveRecord

## v0.2.11

- Adds `request_id` to the action_controller/log_subscriber

## v0.2.10

- Rename `bin/rake` to `bin/tests` to avoid conflicts with rake

## v0.2.9

- Added test apps for Rails and Grape frameworks
- Testing different Grape versions (0.16.2, 0.17.0)
- Improved request logging for Grape
- Merge and send coverage from main gem and Rails/Grape test apps

## v0.2.5

- Allow the log_executor to be configured to either `:single_thread_executor` or `:immediate_executor`
- Test coverage improvement
- Working rails integration
- Minor adjustments to the log_formatter to make it more compatible with log_stasher.

## v0.2.3

- Adds debugging and coverage for sneakers integration

## v0.2.2

- Add an instance method for the `#name` of the appender

## v0.2.1

- Fixed all appenders, it only worked for Sapience::Logger.
- Added method to test exceptions `Sapience.test_exception(:error)`

## v0.2.0

- Rename Appender::File to Appender::Stream. Accept option stream instead of file in `sapience.yml`

## v0.1.12

- Add missing bang to `.deep_symbolize_keys!`

## v0.1.11

- Make sure the default environment is loaded in case all else fails. Warn about this.

## v0.1.10

- Set tags to `{ environment: Sapience.environment }` for sentry

## v0.1.9

- Support sneakers timing implementation

## v0.1.8

- Validate the sentry/raven dsn when creating the appender

## v0.1.7

- Add support for sneakers

## v0.1.6

- Prevent configuring twice (adds double appenders)

## v0.1.5

- Add missing `#time` method for datadog
- Adds coverage for previous release

## v0.1.4

- Add missing `#count` method for datadog
