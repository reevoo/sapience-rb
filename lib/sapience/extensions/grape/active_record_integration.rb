# frozen_string_literal: true
module Sapience
  module Extensions
    module Grape
      module ActiveRecordIntegration
        def self.included(_)
          if defined?(ActiveRecord)
            ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
              event = ActiveSupport::Notifications::Event.new(*args)
              Grape::Timings.append_db_runtime(event)
            end
          end
        end
      end
    end
  end
end
