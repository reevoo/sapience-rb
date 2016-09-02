# encoding: utf-8
# frozen_string_literal: true

require "fileutils"

module FileHelper
  def create_file(file_path, content)
    file_path = File.expand_path(file_path)

    dir_path = File.dirname(file_path)
    FileUtils.makedirs dir_path unless File.exist?(dir_path)

    File.open(file_path, "w") do |file|
      case content
      when ""
        # Write nothing. Create empty file.
      when String
        file.puts content
      when Array
        file.puts content.join("\n")
      end
    end
  end

  def delete_file(file_path)
    File.delete(file_path) if File.exist?(file_path)
  end
end
