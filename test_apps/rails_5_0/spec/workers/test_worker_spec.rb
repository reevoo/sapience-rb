require "rails_helper"
require "serverengine"
require "sneakers"
require "sneakers/runner"
require "external_sneaker"

describe TestWorker, :skip do
  include FileHelper
  let(:message) do
    {
      title: "Cool",
      body: "Hot",
    }
  end

  before do
    @sneakers_worker = ExternalSneaker.new("rake sneakers:run", described_class)
    @sneakers_worker.start
    Sneakers.publish(
      message.to_json,
      to_queue: described_class::QUEUE_NAME,
      routing_key: described_class::ROUTING_KEY,
    )
  end

  after do
    delete_file("config/sapience.yml")
    delete_file(described_class::VERIFICATION_FILE)
  end

  # TODO: Possible make this less flaky or run it with retry (rspec-retry)
  it "runs properly" do
    count = 0
    until File.exist?(described_class::VERIFICATION_FILE)
      sleep 0.1
      count += 1
      expect(true).to be(false) if count > 240
    end
    expect(true).to be(true)
  end
end
