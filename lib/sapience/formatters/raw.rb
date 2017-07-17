# frozen_string_literal: true
require "json"
module Sapience
  module Formatters
    class Raw < Base
      # Returns log messages in Hash format
      def call(log, logger)
        log.to_h(log_host ? logger.host : nil, log_application ? logger.app_name : nil)
      end
    end
  end
end
