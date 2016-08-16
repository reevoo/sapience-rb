require "action_controller/log_subscriber"

class ActionController::LogSubscriber # rubocop:disable ClassAndModuleChildren
  module Inclusions
    # Log as debug to hide Processing messages in production
    def start_processing(event)
      controller_logger(event).debug { "Processing ##{event.payload[:action]}" }
    end

    def process_action(event) # rubocop:disable AbcSize, CyclomaticComplexity, PerceivedComplexity
      controller_logger(event).info do
        payload = event.payload.dup
        payload[:params].except!(*INTERNAL_PARAMS)
        payload.delete(:params) if payload[:params].empty?

        format           = payload[:format]
        payload[:format] = format.to_s.upcase if format.is_a?(Symbol)

        payload[:path]   = extract_path(payload[:path]) if payload.key?(:path)

        exception = payload.delete(:exception)
        if payload[:status].nil? && exception.present?
          exception_class_name = exception.first
          payload[:status]     = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception_class_name)
        end

        # Rounds off the runtimes. For example, :view_runtime, :mongo_runtime, etc.
        payload.keys.each do |key|
          payload[key] = payload[key].to_f.round(2) if key.to_s.match(/(.*)_runtime/)
        end

        payload[:message]        = "Completed ##{payload[:action]}"
        payload[:status_message] = Rack::Utils::HTTP_STATUS_CODES[payload[:status]] if payload[:status].present?
        payload[:duration]       = event.duration
        # Causes excessive log output with Rails 5 RC1
        payload.delete(:headers)
        payload
      end
    end

    def halted_callback(event)
      controller_logger(event).info do
        "Filter chain halted as #{event.payload[:filter].inspect} rendered or redirected"
      end
    end

    def send_file(event)
      controller_logger(event).info("Sent file") { { path: event.payload[:path], duration: event.duration } }
    end

    def redirect_to(event)
      controller_logger(event).info("Redirected to") { { location: event.payload[:location] } }
    end

    def send_data(event)
      controller_logger(event).info("Sent data") { { file_name: event.payload[:filename], duration: event.duration } }
    end

    def unpermitted_parameters(event)
      controller_logger(event).debug do
        unpermitted_keys = event.payload[:keys]
        "Unpermitted parameter#{"s" if unpermitted_keys.size > 1}: #{unpermitted_keys.join(", ")}"
      end
    end

    private

    # Returns the logger for the supplied event.
    # Returns ActionController::Base.logger if no controller is present
    def controller_logger(event)
      if (controller = event.payload[:controller])
        begin
          controller.constantize.logger
        rescue NameError
          ActionController::Base.logger
        end
      else
        ActionController::Base.logger
      end
    end

    def extract_path(path)
      index = path.index("?")
      index ? path[0, index] : path
    end

    def write_fragment(event)
      controller_logger(event).info do
        key_or_path = event.payload[:key] || event.payload[:path]
        { message: "Write fragment #{key_or_path}", duration: event.duration }
      end
    end

    def read_fragment(event)
      controller_logger(event).info do
        key_or_path = event.payload[:key] || event.payload[:path]
        { message: "Read fragment #{key_or_path}", duration: event.duration }
      end
    end

    def exist_fragment(event)
      controller_logger(event).info do
        key_or_path = event.payload[:key] || event.payload[:path]
        { message: "Exist fragment #{key_or_path}", duration: event.duration }
      end
    end

    def expire_fragment(event)
      controller_logger(event).info do
        key_or_path = event.payload[:key] || event.payload[:path]
        { message: "Expire fragment #{key_or_path}", duration: event.duration }
      end
    end

    def expire_page(event)
      controller_logger(event).info do
        key_or_path = event.payload[:key] || event.payload[:path]
        { message: "Expire page #{key_or_path}", duration: event.duration }
      end
    end

    def write_page(event)
      controller_logger(event).info do
        key_or_path = event.payload[:key] || event.payload[:path]
        { message: "Write page #{key_or_path}", duration: event.duration }
      end
    end
  end

  include Inclusions
end
