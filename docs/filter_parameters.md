## Filtering out sensitive data

**NOTE: This is intended for (and will currently only work with) Rack-like applications, which include a `params` key in their `payload` hash**

You may not want to log certain parameters which have sensitive information to be in the logs, e.g. `password`.  This can be set using the `filter_parameters` option when using `configure`:

```ruby
Sapience.configure do |config|
  # Filter the value of "foo" from rack's parameter hash
  config.filter_parameters << 'foo'
end
```

Note that by default this is set to `['password', 'password_confirmation']`, so be careful when explicitly setting, as you may lose this filtering:

```ruby
Sapience.configure do |config|
  # NOTE: password and password_confirmation will no longer be filtered
  config.filter_parameters = ['foo']
end
```

Similarly, *be particularly careful* when setting as `yaml` because this will no longer filter `password` and `password_confirmation`:

```yaml
some_environment:
  # NOTE: password and password_confirmation will no longer be filtered if they're not included in this list
  filter_parameters:
    - foo
```

Any filtered parameter will still show in the `params` field, but it's value will be `[FILTERED]`.