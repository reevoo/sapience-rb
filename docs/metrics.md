## Metrics

For metrics, at the moment, we only support Datadog.

Datadog is a slightly modified version of statsd. On top of the standard statsd API it has support for events.

You can configure datadog through "sapience.yml", using the "metrics" section shown in the example below.
(note that you can use an environment variable, as in the example below, or just put the URL in plain text if you prefer).
```yml
production:
  log_level: info

  metrics:
    datadog:
      url: <%= ENV.fetch("STATSD_URL", "udp://localhost:8125") %>
```
or through ruby code as below:

```ruby
Sapience.metrics = { datadog: { url: ENV["STATSD_URL"] } }
```

Of course, whatever url you use (like for example "udp://localhost:8125"), make sure you have launched the Datadog agent listening to that host and url. See how to install a Datadog agent in the [Datadog Agent Documentation](http://docs.datadoghq.com/guides/basic_agent_usage/).

Then you can send metrics to Datadog using  the following methods:
```ruby
timing(metric, duration = 0, options = {})
increment(metric, options = {})
decrement(metric, options = {})
histogram(metric, amount, options = {})
gauge(metric, amount, options = {})
count(metric, amount, options = {})
time(metric, options = {}, &block)
batch(&block)
event(title, text, options = {})
```

As in the examples below:
```ruby
metrics = Sapience.metrics
metrics.timing("metric-key", 100)
metrics.increment("metric-key")
metrics.decrement("metric-key")
metrics.count("metric-key", -3)
metrics.histogram("metric-key", 2_500)
metrics.gauge("metric-key", 1_000, {})
metrics.event("metric-key", "description about event", {})
metrics.batch do
  metrics.event("metric-key", "description about event", {})
  metrics.increment("another-metric-key", 2)
end
```

### Metric keys and tags

The metric key argument used in all tracking methods can be arbitrary string however we recommend to use combination of names
identifing component of your system joined by dots. All the metric keys are automaticaly prepended with `app_name.environment`.

We use two diferent schemas for key that can be combined in one app:

#### Fully specified key

```
app_name.environment.module.(component)*.event
```

The key fully indetify the source of event and is useful in cases where you don't need to aggregate events
occured in one component, module or whole app. Example:

```ruby
metrics.increment('authentication.sign_in') # full key: booking_app.production.authentication.sign_in
```

#### Partially specified key in combination with tags

```
key: app_name.environment.event_type
tags: event:name, module:name, component:name
```

The key inself doesn't indetify the source of tracked event and is useful in cases where you want to aggregate events
occured in one component, module or whole app. It's handy for event types that can occur in all modules of an app.
We use it mainly for error metrics. Example:

```ruby
metrics.increment('error', tags: %w(error_class:AccessDenied module:authentication component:permissions))
```
