# encoding: utf-8
# frozen_string_literal: true

require "yaml"
require "pathname"

module Sapience
  # This class represents the configuration of the RuboCop application
  # and all its cops. A Config is associated with a YAML configuration
  # file from which it was read. Several different Configs can be used
  # during a run of the sapience program, if files in several
  # directories are inspected.
  module ConfigLoader
    SAPIENCE_FILE       = "sapience.yml".freeze
    SAPIENCE_HOME       = File.realpath(File.join(File.dirname(__FILE__), "..", ".."))
    DEFAULT_FILE        = File.join(SAPIENCE_HOME, "config", "default.yml")

    def self.load_from_file
      file_path = config_file_path
      load_file(file_path)
    end

    class << self
      private

      def config_file_path
        return DEFAULT_FILE unless File.exist?(application_config_file)

        application_config_file
      end

      def application_config_file
        File.join(Rack::Directory.new("").root, "config", SAPIENCE_FILE)
      end

      def load_file(path)
        path = File.absolute_path(path)
        load_yaml_configuration(path)
      end

      def load_yaml_configuration(absolute_path)
        yaml_code = IO.read(absolute_path, encoding: "UTF-8")
        hash      = yaml_safe_load(yaml_code, absolute_path) || {}

        unless hash.is_a?(Hash)
          fail(TypeError, "Malformed configuration in #{absolute_path}")
        end

        hash
      end

      def yaml_safe_load(yaml_code, filename)
        if YAML.respond_to?(:safe_load) # Ruby 2.1+
          if defined?(SafeYAML) && SafeYAML.respond_to?(:load)
            SafeYAML.load(yaml_code, filename,
              whitelisted_tags: %w(!ruby/regexp))
          else
            YAML.safe_load(yaml_code, [Regexp], [], false, filename)
          end
        else
          YAML.load(yaml_code, filename)
        end
      end
    end


  end
end
