# encoding: utf-8
# frozen_string_literal: true

require "yaml"
require "pathname"
require "erb"

module Sapience
  # This class represents the configuration of the RuboCop application
  # and all its cops. A Config is associated with a YAML configuration
  # file from which it was read. Several different Configs can be used
  # during a run of the sapience program, if files in several
  # directories are inspected.
  module ConfigLoader
    SAPIENCE_FILE = "sapience.yml".freeze
    SAPIENCE_HOME = File.realpath(File.join(File.dirname(__FILE__), "..", ".."))
    DEFAULT_FILE  = File.join(SAPIENCE_HOME, "config", "default.yml")

    def self.load_from_file
      default_config     = load_yaml_configuration(config_file_path)
      application_config = load_yaml_configuration(application_config_file)
      merge_configs(default_config, application_config)
    end

    def self.merge_configs(left_config = {}, right_config = {})
      left_config.each do |key, config = {}|
        right = right_config.fetch(key) { Hash.new }
        config.merge!(right)
      end

      (right_config.keys - left_config.keys).each do |left_over_key|
        left_config[left_over_key] = right_config[left_over_key]
      end
      left_config
    end

    class << self
      private

      def config_file_path
        File.absolute_path(DEFAULT_FILE)
      end

      def application_config_file
        File.join(root_dir, "config", SAPIENCE_FILE)
      end

      def root_dir
        if defined?(::Rack::Directory)
          Rack::Directory.new("").root
        else
          Dir.pwd
        end
      end

      def load_yaml_configuration(absolute_path)
        return {} unless File.exist?(absolute_path)
        text      = IO.read(absolute_path, encoding: "UTF-8")
        erb       = ERB.new(text)
        yaml_code = erb.result

        hash = yaml_safe_load(yaml_code, absolute_path) || {}

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
