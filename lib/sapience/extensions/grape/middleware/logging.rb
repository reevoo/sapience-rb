require "grape/middleware/base"

module Sapience
  module Extensions
    module Grape
      module Middleware
        class Logging < ::Grape::Middleware::Base
          ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
            event = ActiveSupport::Notifications::Event.new(*args)
            Grape::Timings.append_db_runtime(event)
          end if defined?(ActiveRecord)

          def initialize(app, options = {})
            super
            @logger = @options[:logger]
          end

          def before
            reset_db_runtime
            start_time
          end

          def after
            stop_time
            @logger.info(parameters)
            nil
          end

          def call!(env)
            super
          end

          protected

          def response
            super
          rescue
            nil
          end

          def parameters # rubocop:disable AbcSize
            {
              status: (response.nil? ? "fail" : response.status),
              time: {
                total: total_runtime,
                db: db_runtime,
                view: view_runtime,
              },
              method: request.request_method,
              path: request.path,
              params: request.params,
              host: request.host,
              ip: (request.env["HTTP_X_FORWARDED_FOR"] || request.env["REMOTE_ADDR"]),
              ua: request.env["HTTP_USER_AGENT"],
            }
          end

          private

          def request
            @request ||= ::Rack::Request.new(env)
          end

          def total_runtime
            ((stop_time - start_time) * 1000).round(2)
          end

          def view_runtime
            total_runtime - db_runtime
          end

          def db_runtime
            Grape::Timings.db_runtime.round(2)
          end

          def reset_db_runtime
            Grape::Timings.reset_db_runtime
          end

          def start_time
            @start_time ||= Time.now
          end

          def stop_time
            @stop_time ||= Time.now
          end
        end
      end
    end
  end
end
