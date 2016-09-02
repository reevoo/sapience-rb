require "rails_helper"
require "serverengine"
require "sneakers"
require "sneakers/runner"
require "external_sneaker"

describe TestWorker, "This is manual labor as we can't verify that sneakers is runnin", :skip do
  include FileHelper
  let(:message) do
    {
      title: "Cool",
      body: "Hot",
    }
  end
  let(:logger) { Sapience[described_class] }

  before do
    @sneakers_worker = ExternalSneaker.new("rake sneakers:run")
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

  it "runs properly" do
    wait(30.seconds).for { File.exist?(described_class::VERIFICATION_FILE) }.to eq(true)
  end
end
