require_relative "../request_format_helper"

module Sapience
  module Extensions
    module Grape
      module Middleware

        class InfoBuilder
          include RequestFormatHelper

          def initialize(env:, start_time:, stop_time:, status:)
            @env = env
            @start_time = start_time
            @stop_time = stop_time
            @status = status
          end

          def params # rubocop:disable AbcSize
            {
              method: request.request_method,
              request_path: request.path,
              format: request_format(request.env),
              status: @status,
              class_name: @env["api.endpoint"].options[:for].to_s,
              action: "index",
              host: request.host,
              ip: (request.env["HTTP_X_FORWARDED_FOR"] || request.env["REMOTE_ADDR"]),
              ua: request.env["HTTP_USER_AGENT"],
              # route: "test_controller#index",
              # message: "Completed #index",
              tags: Sapience.tags,
              params: request.params,
              runtimes: runtimes,
            }
          end

          private

          def request
            @request ||= ::Rack::Request.new(@env)
          end

          def runtimes
            {
              total: total_runtime,
              view: view_runtime,
              db: db_runtime,
            }
          end

          def total_runtime
            ((@stop_time - @start_time) * 1000).round(3)
          end

          def view_runtime
            total_runtime - db_runtime
          end

          def db_runtime
            Grape::Timings.db_runtime.round(3)
          end
        end
      end
    end
  end
end
