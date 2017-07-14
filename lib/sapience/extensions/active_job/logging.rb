# frozen_string_literal: true
# Patch ActiveJob logger
require "active_job/logging"

module ActiveJob::Logging # rubocop:disable ClassAndModuleChildren
  include Sapience::Loggable

  private

  alias orig_tag_logger tag_logger

  def tag_logger(*tags, &block)
    logger.tagged(*tags, &block)
  end
end
