## Configuring with YAML

Sapience provides a default configuration that will be used unless another file or configuration is specified. You can provide a custom

```yaml
---
default:
  filter_parameters:
    - password
    - password_confirmation
  log_executor: single_thread_executor
  log_level: info
  appenders:
    - stream:
        io: STDOUT
        formatter: color

test:
  log_executor: immediate_executor
  log_level: warn
  appenders:
    - stream:
        file_name: log/test.log
        formatter: color

development:
  log_executor: single_thread_executor
  log_level: debug
  log_level_active_record: debug
  appenders:
    - stream:
        file_name: log/development.log
        formatter: color

production:
  log_executor: single_thread_executor
  log_level: warn
  appenders:
    - stream:
        file_name: log/production.log
        formatter: json
```


### Configuration Inheritance

We will use our default (or overriden - see [reevoo_sapience-rb](https://github.com/reevoo/reevoo_sapience-rb) for more info) configuration as a base. Any configuration specified inside a `config/sapience.yml` file will then me merged into the default or overridden config.

The merge will take place not at the top level but at the environment level. This means that everything inside the environment keys will be replaced with a more specific application config.

Then if a configure block is used that will take presedence.