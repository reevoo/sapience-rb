require_relative "../../../../spec/support/file_helper"

class TestWorker
  QUEUE_NAME = :sneakers_queue
  ROUTING_KEY = :sneakers_routing_key
  VERIFICATION_FILE = Rails.root.join("tmp/test_worker.verified")

  include Sneakers::Worker
  include FileHelper

  from_queue QUEUE_NAME, routing_key: ROUTING_KEY

  def work(_message)
    create_file(VERIFICATION_FILE)
    ack!
  end
end
