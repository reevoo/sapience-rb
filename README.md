# Sapience

**Hasslefree auto-configuration for logging, metrics and exception collection.**

[![Build Status](https://travis-ci.org/reevoo/sapience-rb.svg?branch=master)](https://travis-ci.org/reevoo/sapience-rb)[![Code Climate](https://codeclimate.com/github/reevoo/sapience-rb/badges/gpa.svg)](https://codeclimate.com/github/reevoo/sapience-rb)[![Test Coverage](https://codeclimate.com/github/reevoo/sapience-rb/badges/coverage.svg)](https://codeclimate.com/github/reevoo/sapience-rb/coverage)[![Issue Count](https://codeclimate.com/github/reevoo/sapience-rb/badges/issue_count.svg)](https://codeclimate.com/github/reevoo/sapience-rb)

## Background

We searched long and hard for a way to control our logging, error collection and metrics from a single place. The closest we could find that does everything we need is [Semantic Logger](https://github.com/rocketjob/semantic_logger). Unfortunately we couldn't find a good way to control the settings for our projects and would have had to spread our configuration over different initializers and rails configurations for each project. There was no easy way to gain that top level control over the configuration.

This project aims to make it easier to centralise the configuration of these three areas by handling the configuration a little differently.

We have taken a great deal of inspiration from the amazing [Semantic Logger](https://github.com/rocketjob/semantic_logger) and implemented something similar to [Rubocop](https://github.com/bbatsov/rubocop) for handling and overriding how to find configuration. If you want some inspiration for how we do something similar for our projects for Rubocop check: [Reevoocop](https://github.com/reevoo/reevoocop).

## Installation
sapience-rb integrates with rails, grape or can be used standalone.

### Rails
Add the gem:

```ruby
gem "sapience", require: "sapience/rails"
```

### Grape
Add the gem:

```ruby
gem "sapience", require: "sapience/grape"
```

In your Base API class

```ruby
require "sapience/grape"

module Aslan
  module API
    class Base < Grape::API
      use Sapience::Extensions::Grape::Middleware::Logging, logger: Sapience[self]

      # To log all requests even when no route was found use the following:
      route :any, "*path" do
        error!({ error: "No route found" }, 404)
      end
    end
  end
end

```

Also make sure you only use "rescue_from" when you want to return a 500 status. For any other status "dont" use 
"rescue_from".

For example if you have some authentication code that raises an exception when the user is not authenticated, 
dont use "rescue_from" to catch this exception and change the status to 403 within the rescue_from, handle this 
exception instead on the "before" block, or alternatively within your endpoint, like below:


```ruby
before do
  begin
    current_user
  rescue ClientPortalApiClient::Unauthorized
    error!("User is forbidden from accessing this endpoin", 403)
  end
end
```

Likewise, for capturing any other exception for which you want to return a code other than 500, capture your 
exception in the "before" block or within your endpoint, but make sure "rescue_from" is "only" used for 500 
status, as grape will call rescue_from once is gone through all the middleware, so if you change the status 
in a rescue_from, Sapience would not be able to log it correctly. So the below is ok because the rescue_from 
is using status 500:

```ruby
rescue_from :all do |e|
  error!(message: e.message, status: 500)
end
```

**Note**: if you already have got your grape applications sprinkled with calls to API.logger, and you do 
not want to have to replace all those calls to Sapience.logger manually, then just re-assign your logger
after including the Sapience middleware, like below:

```ruby
use Sapience::Extensions::Grape::Middleware::Logging, logger: Sapience[self]
API.logger = Sapience.logger
```


**Note**: If you're using the rackup command to run your server in development, pass the -q flag to silence the default 
rack logger so you don't get double logging.

### Standalone
Add the gem:

```ruby
gem "sapience"
```

Somewhere early in your code execute the following:
```ruby
require "sapience"

Sapience.configure do |config|
  config.app_name = "My Application"
end
```
This will apply the default configuration. See section [Configuration](#configuration) for instructions on
how to configure the library according to your needs.


## Configuration

The sapience configuration can be controlled by either a "sapience.yml" file, or a block of ruby code. Note that if you provide both, the block of ruby code will take precedence.

For a list of available configuration options look at class `Sapience::Configuration`

#### Configuration by sapience.yml file

Add a `config/sapience.yml` file to your application. The config file contains sections for different environments.
When using with rails or grape the environment will be set by the framework. When using as standalone, use ENV
variable `SAPIENCE_ENV` for setting the environment.

Or if you, like us, have many projects that use the same configuration you can create your own gem with a shared .yml config. Have a look at [reevoo/reevoo_sapience-rb](https://github.com/reevoo/reevoo_sapience-rb) for an example . See below an example of how to configure "sapience.yml":

```yaml
default:
  app_name: My Application
  log_level: debug
  appenders:
    - stream:
        io: STDOUT
        formatter: json
  filter_parameters:
    - password
    - password_confirmation

development:
  log_level: debug
  metrics:
    datadog:
      url: <%= ENV.fetch("STATSD_URL", "udp://localhost:8125") %>
  appenders:
    - stream:
        io: STDOUT
        formatter: color
    - stream:
        file_name: log/development.log
        formatter: color
        
staging:
  log_level: info
  error_handler:
    sentry:
      dsn: <%= ENV['SENTRY_DSN'] %>
  metrics:
    datadog:
      url: <%= ENV.fetch("STATSD_URL", "udp://localhost:8125") %>
  appenders:
    - stream:
        io: STDOUT
        formatter: json
        
production:
  log_level: info
  silent_rails: true # make rails logging less noisy
  error_handler:
    sentry:
      dsn: <%= ENV['SENTRY_DSN'] %>
  metrics:
    datadog:
      url: <%= ENV.fetch("STATSD_URL", "udp://localhost:8125") %>
  appenders:
    - stream:
        io: STDOUT
        formatter: json
```

#### Configuration by a block of Ruby code

```ruby
Sapience.configure(force: true) do |config|
  config.app_name = "My Application"
  config.default_level   = :info
  config.backtrace_level = :error
  config.silent_rails = true # make rails logging less noisy
  config.filter_parameters = %w(password password_confirmation)
  config.appenders       = [
      { stream: { io: STDOUT, formatter: :color } },
      { stream: { file_name: "log/json_output.log", formatter: :json } }
  ]
  config.error_handler = { sentry: { dsn: ENV["SENTRY_DSN"] } }
  config.metrics = { datadog: { url: ENV["STATSD_URL"] } }
  config.log_executor    = :single_thread_executor
end
```

For further details about "app_name", "filter_parameters", "appenders", "metrics" and "error_handler" used in both the .yml and the code configurations above, see the links below:

- [app_name](docs/app_name.md)
- [filter_parameters](docs/filter_parameters.md)
- [appenders](docs/appenders.md)
- [metrics](docs/metrics.md)
- [error_handler](docs/error_handler.md)
- [logger](docs/logger.md)


## Running the tests

You need to create the test postgres db, by running the command below:

`createdb rails_app_test`

Then you can run them with the following command:

`bin/tests`

## Environment variables

- `APP_NAME` - If you want to provide an application name for sapience it can be done here.
- `SAPIENCE_ENV` - For applications that don't use rack or rails



## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

