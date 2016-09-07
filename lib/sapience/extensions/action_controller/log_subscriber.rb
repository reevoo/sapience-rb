require "action_controller/log_subscriber"

module Sapience
  module Extensions
    module ActionController
      class LogSubscriber < ::ActionController::LogSubscriber # rubocop:disable ClassLength
        alias_method :orig_start_processing, :start_processing
        alias_method :orig_process_action, :process_action

        # Log as debug to hide Processing messages in production
        def start_processing(event)
          debug { "Processing ##{event.payload[:action]}" }
        end

        def process_action(event) # rubocop:disable AbcSize, CyclomaticComplexity, PerceivedComplexity
          return unless logger.info?
          data      = request(event.payload)
          data.merge! runtimes(event)
          data.merge! exception(event.payload)
          info(data)
        end

        private

        def request(payload) # rubocop:disable AbcSize
          {
            method: payload[:method].upcase,
            request_path: request_path(payload),
            format: format(payload),
            status: payload[:status].to_i,
            controller: payload[:params]["controller"],
            action: payload[:params]["action"],
            host: Sapience.config.host,
            route: "#{payload[:params].delete("controller")}##{payload[:params]["action"]}",
            message: "Completed ##{payload[:params].delete("action")}",
            tags: Sapience.tags,
            params: payload[:params],
          }
        end

        def format(payload)
          if ::ActionPack::VERSION::MAJOR == 3 && ::ActionPack::VERSION::MINOR == 0
            payload[:formats].first
          else
            payload[:format]
          end
        end

        def runtimes(event)
          {
            total: event.duration,
            view: event.payload[:view_runtime],
            db: event.payload[:db_runtime],
          }.each_with_object({}) do |(name, runtime), runtimes|
            runtimes[:runtimes] ||= {}
            runtimes[:runtimes][name] = runtime.to_f.round(2) if runtime
            runtimes
          end
        end

        # Monkey patching to enable exception logging
        def exception(payload)
          if payload[:exception]
            exception, message = payload[:exception]
            message ||= exception.message
            status = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception)
            backtrace = $ERROR_INFO.try(:backtrace).try(:first)
            backtrace ||= exception.backtrace.first
            message = "#{exception}\n#{message}\n#{backtrace}"
            { status: status, error: message }
          else
            {}
          end
        end

        def request_path(payload)
          payload[:path].split("?").first
        end
      end
    end
  end
end
