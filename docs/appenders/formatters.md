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

