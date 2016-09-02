class TestWorker
  include Sneakers::Worker
  QUEUE_NAME  = "sneakers_queue".freeze

  from_queue QUEUE_NAME

  def work(message)
    binding.pry
    puts message
    sleep 0.1
    ack!
  end
end
