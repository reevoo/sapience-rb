## Appenders

One of the things that did not suit us so well with the Semantic Logger approach was that they made a distinction between metrics and appenders. In our view anything that could potentially log something somewhere should be treated as an appender.

There are a number of appenders that each listen to different events and act on its data. It is possible to specify the `level` and `backtrace_level` for each appender by providing (example) `level: :error` to the add_appender method.

- [Stream](stream.md)
- [Sentry](sentry.md)
- [Datadog](datadog.md)
- [Wrapper](wrapper.md)