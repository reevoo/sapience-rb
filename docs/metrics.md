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

Then you can send error metrics to Datadog using  the following methods:
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