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

            handle_raise do
              error = catch(:error) do
                @app_response = @app.call(@env)
                nil # no error thrown
              end
              if error
                @status = error[:status]
                throw(:error, error)
              end
            end
            @app_response
          end

          def handle_raise
            begin
              yield
            rescue StandardError => e
              if e.is_a? PageNotFound
                @status = 404
                throw :error, error_hash
              else
                @status = 500
                raise e
              end
            else
              @status = @app_response.first
            ensure
              after
            end
          end

          def error_hash
            {:message=>
              {:error=>"No route found", :status=>404}, :status=>404, :headers => {}
            }
          end

          def before
            reset_db_runtime
            start_time
          end

          def after
            stop_time

            builder = InfoBuilder.new(
              env: env, start_time: start_time, stop_time: stop_time, status: @status,
            )
            @logger.info(builder.params)
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
