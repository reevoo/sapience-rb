require "serverengine"
require "sneakers"

p ENV.fetch("AMQP") { "amqp://guest:guest@localhost:5672" }

Sneakers.configure(
  amqp:               ENV.fetch("AMQP") { "amqp://guest:guest@localhost:5672" },
  exchange_type:      :direct,
  log:                Sapience[Sneakers], # Log file
  exchange:           "sapience", # AMQP exchange
  durable:            false, # Is queue durable?
  ack:                true, # Must we acknowledge?
  metrics:            Sapience.metrix,
)
Sapience.logger.level = Logger::DEBUG
