## Stream

- [Appenders](README.md)
  - [Stream Appender](stream.md)
  - [Sentry Appender](sentry.md)
  - [Datadog Appender](datadog.md)
  - [Wrapper Appender](wrapper.md)

Stream appenders are basically a log stream. You can add as many stream appenders as you like logging to different locations.

```ruby
Sapience.add_appender(:stream, file: "log/sapience.log", formatter: :json)
Sapience.add_appender(:stream, io: STDOUT, formatter: :color, level: :trace)
```