class LogFactory
  # rubocop:disable ParameterLists, LineLength
  def self.build(level: nil, thread_name: nil, name: nil, message: nil, payload: nil, time: nil, duration: nil, tags: nil, level_index: nil, exception: nil, metric: nil, backtrace: nil, metric_amount: nil)
    Sapience::Log.new(
      level,
      thread_name,
      name,
      message,
      payload,
      time,
      duration,
      tags,
      level_index,
      exception,
      metric,
      backtrace,
      metric_amount,
    )
  end
end
