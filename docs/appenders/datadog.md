## Datadog

Datadog is a slightly modified version of statsd. On top of the standard statsd API it has support for events.

```ruby
Sapience.add_appender(:datadog, url: "udp://localhost:8125")
```

The appender will then be listening to anything that is logged with a `metric: "company/project/metric-name"` key. Details about the API can be found in [dogstatsd-ruby](https://github.com/DataDog/dogstatsd-ruby).

The appender can also be used directly through: `Sapience.metrics`

```ruby
metrics = Sapience.metrics
metrics.timing("company/project/metric-name", 100)
metrics.increment("company/project/metric-name", 10)
metrics.decrement("company/project/metric-name", 5)
metrics.histogram("company/project/metric-name", 2_500)
metrics.gauge("company/project/metric-name", 1_000, {})
metrics.event("company/project/metric-name", "description about event", {})
metrics.batch do
  metrics.event("company/project/metric-name", "description about event", {})
  metrics.increment("company/project/another-metric-name", 2)
end
```