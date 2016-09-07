shared_context "logs" do
  let(:level) { :info }
  let(:thread_name) { "Custom Thread" }
  let(:name) { "Alex" }
  let(:message) { "Sapience is really cool" }
  let(:payload) {}
  let(:time) { Time.now }
  let(:duration) { 9_999 }
  let(:tags) { %w(tag_one tag_two) }
  let(:level_index) { Sapience.config.level_to_index(level) }
  let(:exception_message_one) { "Error 1" }
  let(:exception_message_two) { "Error 2" }
  let(:exception) do
    begin
      begin
        fail exception_message_one
      rescue RuntimeError
        raise exception_message_two
      end
    rescue RuntimeError => e
      e
    end
  end
  let(:metric) { "sapience.performance.rocks" }
  let(:backtrace) do
    %W(
      #{File.join(Sapience.root, "lib/sapience.rb")}:10
      #{File.join(Sapience.root, "lib/sapience/sapience.rb")}:46
    )
  end
  let(:metric_amount) { 2_000_000 }
  let(:log) do
    LogFactory.build(
      level: level,
      thread_name: thread_name,
      name: name,
      message: message,
      payload: payload,
      time: time,
      duration: duration,
      tags: tags,
      level_index: level_index,
      exception: exception,
      metric: metric,
      backtrace: backtrace,
      metric_amount: metric_amount,
    )
  end
end

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
