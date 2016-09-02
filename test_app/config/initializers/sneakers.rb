require "serverengine"
require "sapience/rails"
require "sneakers"

Sneakers.configure(
  amqp:               "amqp://guest:guest@localhost:5672",
  exchange_type:      :direct,
  log:                Sapience[Sneakers], # Log file
  exchange:           "sapience", # AMQP exchange
  durable:            false, # Is queue durable?
  ack:                true, # Must we acknowledge?
  metrics:            Sapience.metrix,
)
Sapience.logger.level = Logger::DEBUG
