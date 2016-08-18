# Replace rack started message with a semantic equivalent
class Rails::Rack::Logger # rubocop:disable ClassAndModuleChildren
  def started_request_message(request)
    {
      message: "Started",
      method:  request.request_method,
      path:    request.filtered_path,
      ip:      request.ip,
    }
  end
end
