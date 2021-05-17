## Formatters

Formatters can be specified by using the key `formatter: :camelized_formatter_name`. **Note**: Only the File appender supports custom formatters.

### Color

`formatter: :color` - gives colorized output. Useful for `test` and `development` environments.

### Default

`formatter: :default` - logs a string. Inspired by how access logs for Nginx are logged.

### JSON

`formatter: :json` - logs are saved as a single line json. Useful for production like environments.
The json formatter can be configured to filter out select log fields. The following configuration demonstrates this:

```yaml
json_formatter: &json_slim
  json:
    exclude_fields:
      - "name"
      - "request_id"
      - "thread"
      - "pid"
      - "level_index"
      - "host"
      - "app_name"
      - "request_id"
      - "action"
      - "controller"
      - "route"
      - "file"
      - "line"
      - "format"
      - "tags"

ci:
  log_level: warn
  appenders:
    - stream:
        io: STDOUT
        formatter: color

production:
  log_level: info
  appenders:
    - stream:
        io: STDOUT
        formatter:
          <<: *json_slim

staging:
  log_level: info
  appenders:
    - stream:
        io: STDOUT
        formatter:
          <<: *json_slim

development:
  log_level: debug
  appenders:
    - stream:
        io: STDOUT
        formatter: json
```

### RAW

`formatter: :raw` - logs are saved as a single line ruby hash. Useful for production like environments and is used internally for the Sentry appender.

