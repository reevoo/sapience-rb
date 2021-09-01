# frozen_string_literal: true
require "grape/middleware/base"
require_relative "info_builder"

module Sapience
  module Extensions
    module Grape
      module Middleware
        class Logging < ::Grape::Middleware::Base

          if defined?(ActiveRecord)
            ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
              event = ActiveSupport::Notifications::Event.new(*args)
              Grape::Timings.append_db_runtime(event)
            end
          end

          def initialize(app, options = {})
            super
            @logger = @options[:logger]
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

            builder = InfoBuilder.new(
              env: env, start_time: start_time, stop_time: stop_time, status: @status
            )
            @logger.info(builder.params)
          end

          def after_exception(exc) # rubocop:disable Lint/UnusedMethodArgument
            @status = 500
            after
          end

          def after_failure(error)
            @status = error[:status]
            after
          end

          private

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
