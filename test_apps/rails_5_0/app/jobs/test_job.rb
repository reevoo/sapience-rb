require "application_job"
require_relative "../../../../spec/support/file_helper"

class TestJob < ApplicationJob
  VERIFICATION_FILE = Rails.root.join("tmp/test_job.verified")
  queue_as :test_queue
  include FileHelper

  def perform
    create_file(VERIFICATION_FILE)
  end
end
