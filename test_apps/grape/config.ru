# This file is used by Rack-based servers to start the application.

require_relative 'lib/ping/api'

run Ping::API
