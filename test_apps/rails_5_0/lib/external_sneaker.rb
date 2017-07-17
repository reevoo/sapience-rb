# frozen_string_literal: true
require "timeout"

class ExternalSneaker
  attr_accessor :worker_pid, :start_command, :workers

  def initialize(start_command, *workers)
    fail ArgumentError, "start_command was expected" if start_command.nil?
    self.workers = workers.map(&:to_s).join(",")
    self.start_command = start_command
  end

  def start
    puts "Trying to start #{start_command}..."
    self.worker_pid = fork do
      start_child
    end

    at_exit do
      stop_child
    end
  end

  private

  def start_child
    exec({ "RAILS_ENV" => Rails.env, "WORKERS" => workers }, start_command)
  end

  def stop_child # rubocop:disable AbcSize
    puts "Trying to stop #{start_command}, pid: #{worker_pid}"

    # send TERM and wait for exit
    Process.kill("TERM", worker_pid)

    begin
      Timeout.timeout(10) do
        Process.waitpid(worker_pid)
        puts "Process #{start_command} stopped successfully"
      end
    rescue Timeout::Error
      # Kill process if could not exit in 10 seconds
      puts "Sending KILL signal to #{start_command}, pid: #{worker_pid}"
      Process.kill("KILL", worker_pid)
    end
  end
end
