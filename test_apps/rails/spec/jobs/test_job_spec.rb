require "rails_helper"
require "serverengine"
require "sneakers"
require "sneakers/runner"
require "external_sneaker"

describe TestJob do
  include FileHelper
  include ActiveJob::TestHelper
  let(:metrics) { Sapience.add_appender(:datadog) }
  let(:tags) do
    %w(name:test queue:test_queue)
  end
  let(:message) do
    {
      title: "Cool",
      body: "Hot",
    }
  end
  let(:logger) { Sapience[described_class] }

  after do
    delete_file("config/sapience.yml")
    delete_file(described_class::VERIFICATION_FILE)
  end

  # TODO: Possible make this less flaky or run it with retry (rspec-retry)
  it "runs properly" do
    expect(metrics).to receive(:increment).with("activejob.perform", tags: tags)
    expect(metrics).to receive(:timing).with("activejob.perform.time", kind_of(Float), tags: tags)

    perform_enqueued_jobs do
      TestJob.perform_later
    end
  end
end
