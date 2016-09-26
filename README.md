# Sapience

**Hasslefree autoconfiguration for logging, metrics and exception collection.**

[![Build Status](https://travis-ci.org/reevoo/sapience-rb.svg?branch=master)](https://travis-ci.org/reevoo/sapience-rb)[![Code Climate](https://codeclimate.com/github/reevoo/sapience-rb/badges/gpa.svg)](https://codeclimate.com/github/reevoo/sapience-rb)[![Test Coverage](https://codeclimate.com/github/reevoo/sapience-rb/badges/coverage.svg)](https://codeclimate.com/github/reevoo/sapience-rb/coverage)[![Issue Count](https://codeclimate.com/github/reevoo/sapience-rb/badges/issue_count.svg)](https://codeclimate.com/github/reevoo/sapience-rb)

## Background

We searched long and hard for a way to control our logging, error collection and metrics from a single place. The closest we could find that does everything we need is [Semantic Logger](https://github.com/rocketjob/semantic_logger). Unfortunately we couldn't find a good way to control the settings for our projects and would have had to spread our configuration over different initializers and rails configurations for each project. There was no easy way to gain that top level control over the configuration.

This project aims to make it easier to centralize the configuration of these three areas by handling the configuration a little differently.

We have taken a hug deal of inspiration from the amazing [Semantic Logger](https://github.com/rocketjob/semantic_logger) and implemented something similar to [Rubocop](https://github.com/bbatsov/rubocop) for handling and overriding how to find configuration. If you want some inspiration for how we do something similar for our projects for Rubocop check: [Reevoocop](https://github.com/reevoo/reevoocop).

## Setup

First of all we need to require the right file for the project. There are currently two frameworks supported (rails and grape).

### Rails  

```ruby
gem "sapience-rb", require: "sapience/rails"
```

### Grape 

```ruby
gem "sapience-rb", require: "sapience/grape"
```

In your Base API class

```ruby
require "sapience/grape"

module Aslan
  module API
    class Base < Grape::API
      use Sapience::Extensions::Grape::Middleware::Logging, logger: Sapience[self]
      
      # To log all requests even when no route was found try the following:
      route :any, "*path" do
        error!({ error: "No route found" }, 404)
      end 
    end
  end
end

```

### Configuration

The sapience configuration can be controlled by a `config/sapience.yml` file or if you like us have many projects that use the same configuration you can create your own gem with a shared config. Have a look at [reevoo/reevoo_sapience-rb](https://github.com/reevoo/reevoo_sapience-rb)

The `app_name` is required to be configured. Sapience will fail on startup if app_name isn't configured properly.

```ruby 
Sapience.configure do |config|
  config.default_level   = :info
  config.backtrace_level = :error
  config.app_name        = "my_app"
  config.appenders       = [
    { stream: { io: STDOUT, formatter: :color } },
    { sentry: { dsn: "https://username:password@app.getsentry.com/00000" } },
    { datadog: { url: "udp://localhost:8125" } },
  ]
  config.log_executor    = :single_thread_executor
end
```

Sapience provides a default configuration that will be used unless another file or configuration is specified. You can provide a custom 

```yaml
---
default:
  log_executor: single_thread_executor
  log_level: info
  appenders:
    - stream:
        io: STDOUT
        formatter: color

test:
  log_executor: immediate_executor
  log_level: warn
  appenders:
    - stream:
        file_name: log/test.log
        formatter: color

development:
  log_executor: single_thread_executor
  log_level: debug
  appenders:
    - stream:
        file_name: log/development.log
        formatter: color

production:
  log_executor: single_thread_executor
  log_level: warn
  appenders:
    - stream:
        file_name: log/production.log
        formatter: json
```

## Appenders

One of the things that did not suite us so well with the Semantic Logger approach was that they made a distinction between metrics and appenders. In our view anything that should potentially log something somewhere should be treated as an appender.

There are a number of appenders that all listen to different events and act on its data. It is possible to specify the `level` and `backtrace_level` for each appender by providing (example) `level: :error` to the add_appender method.


### Stream

Stream appenders are basically a log stream. You can add as many stream appenders as you like logging to different locations. 

```ruby
Sapience.add_appender(:stream, file: "log/sapience.log", formatter: :json)
Sapience.add_appender(:stream, io: STDOUT, formatter: :color, level: :trace)
```

### Sentry

The sentry appender handles sending errors to sentry. It's backtrace and log level can be configured by for instance `level: :info` and `backtrace_level: :debug`. The `level` configuration tells sentry to log starting at that level while the `backtrace_level` tells sentry to only collect backtrace starting at that level.

```ruby
Sapience.add_appender(
  :sentry, 
  dsn: "https://username:password@app.getsentry.com/00000", 
  level: :error, 
  backtrace_level: :error
)
```

#### Test exceptions

If you want to quickly verify that your appenders are handling exceptions properly. You can use the following method to 
generate and log an exception at any given level.

```ruby
Sapience.test_exception(:error)
```

### Datadog

Datadog is a slightly modified version of statsd. On top of the standard statsd API it has support for events.

```ruby
Sapience.add_appender(:datadog, url: "udp://localhost:8125")
```

The appender will then be listening to anything that is logged with a `metric: "company/project/metric-name"` key. Details about the API can be found in [dogstatsd-ruby](https://github.com/DataDog/dogstatsd-ruby).

The appender can also be used directly through: `Sapience.metrics`

```ruby
metrics = Sapience.metrics
metrics.timing("company/project/metric-name", 100)
metrics.increment("company/project/metric-name", 10)
metrics.decrement("company/project/metric-name", 5)
metrics.histogram("company/project/metric-name", 2_500)
metrics.gauge("company/project/metric-name", 1_000, {})
metrics.event("company/project/metric-name", "description about event", {})
metrics.batch do 
  metrics.event("company/project/metric-name", "description about event", {})
  metrics.increment("company/project/another-metric-name", 2)
end
```


### Wrapper

The wrapper is useful when you already have a logger you want to use but want to use Sapience. The wrapper appender will when called use the logger provided to store the log data.

```ruby
Sapience.add_appender(:wrapper, logger: Logger.new(STDOUT))
```

## Formatters

Formatters can be specified by using the key `formatter: :camelized_formatter_name`. **Note**: Only the File appender supports custom formatters.

### Color

`formatter: :color` - gives colorized output. Useful for `test` and `development` environments.

### Default 

`formatter: :default` - logs a string. Inspired by how access logs for Nginx are logged.

### JSON 

`formatter: :json` - logs are saved as a single line json. Useful for production like environments.

### RAW 

`formatter: :raw` - logs are saved as a single line ruby hash. Useful for production like environments and is used internally for the Sentry appender.

## Running the tests

`bin/tests`

## Environment variables

`SAPIENCE_APP_NAME` - If you want to provide an application name for sapience
`SAPIENCE_ENV` - For applications that don't use rack or rails

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/reevoo/sapience. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

