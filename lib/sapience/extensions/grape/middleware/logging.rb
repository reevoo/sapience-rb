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
                @error = error
                throw(:error, error)
              end
            end
            @app_response
          end

          def handle_raise
            begin
              yield
            rescue StandardError => e
              if e.class.name =~ %r{NotFound}
                @error = build_error(e, 404)
                throw :error, @error
              else
                @error = build_error(e, 500)
                raise e
              end
            else
              @status = @app_response.first
            ensure
              after
            end
          end

          def build_error(e, code)
            @status = code
            {
              message: {
                error: "#{e.class.name} - #{e.message}", status: code},
              status: code,
              headers: {}
            }
          end

          def before
            @log_builder = InfoBuilder.start
          end

          def after
            @log_builder.stop(env: env, status: @status, error: @error)
            @logger.info(@log_builder.params)
          end
        end
      end
    end
  end
end
