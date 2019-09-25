# frozen_string_literal: true

module Sapience
  module Extensions
    module Sinatra
      module Middleware
        class Logging

          if defined?(ActiveRecord)
            ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
              event = ActiveSupport::Notifications::Event.new(*args)
              Sinatra::Timings.append_db_runtime(event)
            end
          end

          def initialize(app, options = {})
            @app = app
            @logger = options[:logger]
          end

          def call(env)
            call!(env)
          end

          protected

          def call!(env)
            @env = env
            before
            error = catch(:error) do
              begin
                @app_response = @app.call(@env)
              rescue StandardError => e
                after_exception(e)
                raise e
              end
              nil
            end
            if error
              after_failure(error)
              throw(:error, error)
            else
              @status, = *@app_response
              after
            end
            @app_response
          end

          def before
            reset_db_runtime
            start_time
          end

          def after
            stop_time
            @logger.info(parameters)
          end

          def after_exception(exc) # rubocop:disable Lint/UnusedMethodArgument
            @status = 500
            after
          end

          def after_failure(error)
            @status = error[:status]
            after
          end

          def parameters # rubocop:disable AbcSize
            {
              method: request.request_method,
              request_path: @env["REQUEST_URI"] || @env["PATH_INFO"],
              status: @status,
              route: @env["sinatra.route"].to_s,
              host: request.host,
              ip: (request.env["HTTP_X_FORWARDED_FOR"] || request.env["REMOTE_ADDR"]),
              ua: request.env["HTTP_USER_AGENT"],
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
            @request ||= ::Rack::Request.new(@env)
          end

          def total_runtime
            ((stop_time - start_time) * 1000).round(3)
          end

          def view_runtime
            total_runtime - db_runtime
          end

          def db_runtime
            Sinatra::Timings.db_runtime.round(3)
          end

          def reset_db_runtime
            Sinatra::Timings.reset_db_runtime
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
