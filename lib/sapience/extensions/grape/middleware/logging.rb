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

          protected

          def parameters # rubocop:disable AbcSize
            {
              method: request.request_method,
              request_path: request.path,
              format: "json",
              status: response.try(:status),
              class_name: env["api.endpoint"].options[:for].to_s,
              action: "index",
              host: request.host,
              ip: (request.env["HTTP_X_FORWARDED_FOR"] || request.env["REMOTE_ADDR"]),
              ua: request.env["HTTP_USER_AGENT"],
              # route: "test_controller#index",
              # message: "Completed #index",
              tags: Sapience.tags,
              params: request.params,
              runtimes: {
                total: total_runtime,
                view: view_runtime,
                db: db_runtime,
              },
            }
          end

          private

          def request
            @request ||= ::Rack::Request.new(env)
          end

          def total_runtime
            ((stop_time - start_time) * 1000).round(3)
          end

          def view_runtime
            total_runtime - db_runtime
          end

          def db_runtime
            Grape::Timings.db_runtime.round(3)
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
