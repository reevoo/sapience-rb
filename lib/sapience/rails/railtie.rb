require "sapience"

module Sapience
  module Rails
    class Railtie < ::Rails::Railtie
      config.before_configuration do
        Sapience.add_appender(:stream, io: STDOUT, level: :warn, formatter: :color)
        ::Rails.logger = Sapience[::Rails]
      end
    end
  end
end
