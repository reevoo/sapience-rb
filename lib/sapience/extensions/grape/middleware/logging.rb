# frozen_string_literal: true
require "grape/middleware/base"
require_relative "../request_format_helper"
require_relative "../active_record_integration"
require_relative "../sequel_integration"

module Sapience
  module Extensions
    module Grape
      module Middleware
        class Logging < ::Grape::Middleware::Base
          include RequestFormatHelper

          def initialize(app, options = {})
            super
            @logger = @options[:logger]
            ActiveRecordIntegration.plug_in
            SequelIntegration.plug_in
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

          def after_exception(exc)
            Sapience.push_tags(exc.class.name, exc.message)
            @status = 500
            after
          end

          def after_failure(error)
            Sapience.push_tags(error[:message])
            @status = error[:status]
            after
          end

          def parameters # rubocop:disable AbcSize
            {
              method: request.request_method,
              request_path: request.path,
              format: request_format(request.env),
              status: @status,
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
