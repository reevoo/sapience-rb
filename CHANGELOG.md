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
