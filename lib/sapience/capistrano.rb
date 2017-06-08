# The capistrano recipes in plugins are automatically
# loaded from here.  From gems, they are available from
# the lib directory.  We have to make them available from
# both locations

require 'capistrano/version'

if defined?(Capistrano::VERSION) && Capistrano::VERSION.to_s.split('.').first.to_i >= 3
  require_relative 'recipes/capistrano3'
else
  require_relative 'recipes/capistrano2'
end

