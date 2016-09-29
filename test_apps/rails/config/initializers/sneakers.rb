require "serverengine"
require "sneakers"

Sneakers.configure(
  amqp:          ENV.fetch("AMQP") { "amqp://guest:guest@localhost:5672" },
  exchange_type: :direct,
  log:           Sapience[Sneakers], # Log file
  exchange:      "sapience", # AMQP exchange
  durable:       false, # Is queue durable?
  ack:           false, # Must we acknowledge?
  metrics:       Sapience.metrics,
  heartbeat:     nil,
)
Sapience.logger.level = Logger::DEBUG
