# frozen_string_literal: true
module Sapience
  module Extensions
    module Grape
      module SequelIntegration
        def self.included(_)
          if defined?(Sequel)
            Sequel::Database.class_eval do
              alias_method :original_log_duration, :log_duration
          
              def log_duration(duration, message)
                original_log_duration(duration, message)
                Grape::Timings.db_runtime = Grape::Timings.db_runtime + (duration * 1000) # convert to ms
              end
            end
          end
        end
      end
    end
  end
end
