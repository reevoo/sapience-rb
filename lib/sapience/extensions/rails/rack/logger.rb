# Replace rack started message with a semantic equivalent
class Rails::Rack::Logger # rubocop:disable ClassAndModuleChildren
  alias started_request_message_original started_request_message
  def started_request_message(request)
    {
      message: "Started",
      method:  request.request_method,
      path:    request.filtered_path,
      ip:      request.ip,
    }
  end
end
