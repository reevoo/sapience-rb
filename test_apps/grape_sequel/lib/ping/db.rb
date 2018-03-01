require "sequel"
require "sapience"

module Ping
  DB = Sequel.connect(
    adapter: "postgres", 
    host: ENV.fetch("POSTGRES_HOST"),
    user: ENV.fetch("POSTGRES_USER"),
    password: ENV.fetch("POSTGRES_PASSWORD"),
    database: 'tests',
    logger: Sapience[self],
  )
end
