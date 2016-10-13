### Wrapper

The wrapper is useful when you already have a logger you want to use but want to use Sapience. The wrapper appender will when called use the logger provided to store the log data.

```ruby
Sapience.add_appender(:wrapper, logger: Logger.new(STDOUT))
```