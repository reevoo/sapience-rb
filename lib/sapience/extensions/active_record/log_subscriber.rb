require "active_support/notifications"
require "active_record/log_subscriber"

module Sapience
  module Extensions
    module ActiveRecord
      class LogSubscriber < ::ActiveRecord::LogSubscriber
        include Sapience::Loggable

        def identity(event)
          lsevent = logstash_event(event)
          logger << lsevent.to_json + "\n" if logger && lsevent
        end
        alias_method :sql, :identity

        private

        def logstash_event(event)
          data = event.payload

          return if "SCHEMA" == data[:name]

          data.merge! runtimes(event)
          data.merge! extract_sql(data)
          # data.merge! extract_custom_fields(data)

          tags = ["request"]
          tags.push("exception") if data[:exception]
          LogStasher.build_logstash_event(data, tags)
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
      end
    end
  end
end
