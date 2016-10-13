## Configuration 

The sapience configuration can be controlled by a `config/sapience.yml` file or if you like us have many projects that use the same configuration you can create your own gem with a shared config. Have a look at [reevoo/reevoo_sapience-rb](https://github.com/reevoo/reevoo_sapience-rb)

The `app_name` is required to be configured. Sapience will fail on startup if app_name isn't configured properly.

- [Block Configuration](block.md)
- [YAML Configuration](yaml.md)


#### App name

Sapience requires an application name to be set for your logs and such. We decided not to guess what name you want to give your application so there will be no magic involved here. There are 3 different ways of configuring the app_name for Sapience.

##### Environment variables

This is the preferable way. If you have many environments look into using something like dotenv locally and use the power of devops and automation for your production environments.

```bash
APP_NAME="My Application" bundle exec rails server -p 9000
```

##### Configuration file

If you are in need of overriding the sapience default configuration an app_name can be used for any environment but we recommend you specify the app_name for the default section. That way you don't have to specify app_name for each environment and avoid some duplicated keys. Of course if you need to specify different app names for various environments by all means do.

```yaml
---
default:
  app_name: My Application
```

##### Configuration block

This will be the top priority and is the first check. The reasoning is that if someone has taken the time to use configure with a block that should override anything set in file configuration or environment.

```ruby
Sapience.configure do |config|
  config.app_name = "My Application"
end
```
