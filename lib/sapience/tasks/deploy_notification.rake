namespace :sapience do
  desc "Send deploy notification"
  task :deploy_notification, [:sha] => [:environment] do |t, args|
    sha = args[:sha]
    fail ArgumentError, 'Argument "sha" is missing' unless sha

    datadog_event_key = "#{Sapience.metrics.namespace}.deploy"

    Sapience.metrics.event(datadog_event_key, sha, aggregation_key: datadog_event_key)
  end
end

