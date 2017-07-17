# frozen_string_literal: true
require "serverengine"
require "sneakers"
require "sapience"

Sneakers.configure(
  amqp:          ENV.fetch("AMQP") { "amqp://guest:guest@localhost:5672" },
  exchange_type: :direct,
  log:           Sapience[Sneakers], # Log file
  exchange:      "sapience", # AMQP exchange
  durable:       false, # Is queue durable?
  ack:           true, # Must we acknowledge?
  metrics:       Sapience.metrics,
  heartbeat:     nil,
)
