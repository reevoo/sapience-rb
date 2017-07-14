# frozen_string_literal: true
require "thread"

class Thread
  # Returns the name of the current thread
  # Default:
  #    String representation of this thread's object_id
  def name
    @name ||= object_id.to_s
  end

  # Set the name of this thread
  def name=(name)
    @name = name.to_s
  end
end
