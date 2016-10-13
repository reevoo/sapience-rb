## Configuring within a ruby block

```ruby
Sapience.configure do |config|
  config.default_level   = :info
  config.log_level_active_record = :debug
  config.backtrace_level = :error
  config.appenders       = [
    { stream: { io: STDOUT, formatter: :color } },
    { sentry: { dsn: "https://username:password@sentry.io/00000" } },
    { datadog: { url: "udp://localhost:8125" } },
  ]
  config.log_executor    = :single_thread_executor
end
```