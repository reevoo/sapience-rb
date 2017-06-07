# The capistrano recipes in plugins are automatically
# loaded from here.  From gems, they are available from
# the lib directory.  We have to make them available from
# both locations

require_relative 'recipes/capistrano2'
# require_relative 'recipes/capistrano3'
