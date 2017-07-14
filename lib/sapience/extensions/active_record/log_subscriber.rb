# frozen_string_literal: true
require "active_support/notifications"
require "active_record/log_subscriber"

module Sapience
  module Extensions
    module ActiveRecord
      class LogSubscriber < ::ActiveRecord::LogSubscriber
        include Sapience::Loggable

        def identity(event)
          event = normalize(event)
          debug(event) if logger && event
        end
        alias sql identity

        private

        def normalize(event)
          data = event.payload

          return if data[:name] == "SCHEMA"

          data.merge! runtimes(event)
          data.merge! extract_sql(data)

          data.merge! tags(data)
        end

        def runtimes(event)
          if event.duration
            { duration: event.duration.to_f.round(2) }
          else
            {}
          end
        end

        def extract_sql(data)
          { sql: data[:sql].squeeze(" ") }
        end

        def tags(data)
          tags = Sapience.tags.dup
          tags.push("request")
          tags.push("exception") if data[:exception]
          { tags: tags }
        end
      end
    end
  end
end
