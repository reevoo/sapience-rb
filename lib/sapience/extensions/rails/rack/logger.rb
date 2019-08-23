# frozen_string_literal: true
# Replace rack started message with a semantic equivalent
# request attributes taken from:
# https://github.com/rails/rails/blob/3-2-stable/actionpack/lib/action_dispatch/http/request.rb

class Rails::Rack::Logger # rubocop:disable ClassAndModuleChildren
  alias started_request_message_original started_request_message
  def started_request_message(request) # rubocop:disable AbcSize
    {
      message: "Started #{request.request_method} #{request.filtered_path}",
      method:  request.request_method,
      path:    request.filtered_path,
      fullpath: request.fullpath,
      original_fullpath: request.original_fullpath,
      ip:      request.env["HTTP_X_FORWARDED_FOR"] || request.remote_addr,
      client_ip: request.ip,
      remote_ip: request.remote_ip,
      remote_host: request.env["HTTP_X_FORWARDED_HOST"] || request.remote_host,
      content_type: request.media_type,
      request_id: request.uuid,
    }
  end
end
