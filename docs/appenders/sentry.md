## Sentry

- [Appenders](README.md)
  - [Stream Appender](stream.md)
  - [Sentry Appender](sentry.md)
  - [Datadog Appender](datadog.md)
  - [Wrapper Appender](wrapper.md)

The sentry appender handles sending errors to [sentry](https://sentry.io). It's backtrace and log level can be configured by for instance `level: :info` and `backtrace_level: :debug`. The `level` configuration tells sentry to log starting at that level while the `backtrace_level` tells sentry to only collect backtrace starting at that level.

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