We have two different types of appenders, see below.


## Stream


Stream appenders are basically a log stream. You can add as many stream appenders as you like logging to different locations.

```ruby
Sapience.add_appender(:stream, file: "log/sapience.log", formatter: :json)
Sapience.add_appender(:stream, io: STDOUT, formatter: :color, level: :trace)
```

or using the sapience.yml file:

```yml
appenders:
 - stream:
     io: STDOUT
     formatter: color
 - stream:
     file_name: log/development.log
     formatter: color
```
You can specify the formatter for each stream, click in the link below to see the list of formatters available:

- [formatters](appenders/formatters.md)



### Wrapper

The wrapper is useful when you already have a logger you want to use but want to use Sapience. The wrapper appender will when called use the logger provided to store the log data.

```ruby
Sapience.add_appender(:wrapper, logger: Logger.new(STDOUT))
```
