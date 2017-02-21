## Error Handling

At the moment we only support [sentry](https://sentry.io) for error alerting.

You can configure the sentry DNS through "sapience.yml", using the "error_handler" section shown in the example below.
(note that you can use an environment variable, as in the example below, or just put the DNS in plain text if you prefer).
```yml
production:
  log_level: info

  error_handler:
    sentry:
      dsn: <%= ENV['SENTRY_DSN'] %>

```
or through ruby code as below:

```ruby
Sapience.error_handler = { sentry: { dsn: ENV["SENTRY_DSN"] } }
```
Then you can send error messages to Sentry using the following two public methods in Sapience:

```ruby
  capture_exception(exception, payload = {})
  capture_message(message, payload = {})
```

As in the example below:
```ruby
begin
  (do somehting)
rescue MyException => e
  Sapience.capture_exception(e)
  raise e
end
```

You can also test that you've configured the DNS correctly by using the "test_exception" method, that will send a test message to your configured Sentry project. See below.

```ruby
Sapience.test_exception(:error)
```