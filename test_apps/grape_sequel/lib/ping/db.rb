require "sequel"
require "sapience"

module Ping
  def self.db
    @db ||= Sequel.connect(
      adapter: "postgres",
      host: ENV.fetch("POSTGRES_HOST", "localhost"),
      user: ENV["POSTGRES_USER"],
      password: ENV["POSTGRES_PASSWORD"],
      database: "tests",
      logger: Sapience[self],
    )
  end
end
