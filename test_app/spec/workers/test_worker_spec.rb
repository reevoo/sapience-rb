require "rails_helper"
require "serverengine"
require "sneakers"
require "sneakers/runner"

describe TestWorker do
  let(:message) do
    {
      title: "Cool",
      body: "Hot",
    }
  end
  let(:logger) { Sapience[described_class] }

  before do
    logger.info 'spawning worker'
    @worker_pid = Process.spawn('bin/sneakers')
    logger.info "spawned worker with pid '#{@worker_pid}"
  end

  after do
    if @worker_pid
      # If we don't get a response in a reasonable number of seconds...give up
      begin
        Timeout.timeout(20) do
          logger.info "stopping worker with pid '#{@worker_pid}'"
          Process.kill(ServerEngine::Daemon::Signals::IMMEDIATE_STOP, @worker_pid)
          _pid, status = Process.wait2(@worker_pid)
          logger.info "worker with pid '#{@worker_pid}' stopped"
          expect(status.exitstatus).to eq(0), "expected #{@worker_pid} to stop with exit code 0, got '#{status.exitstatus}'"
        end
      rescue Timeout::Error
        msg = "timeout processing worker with pid '#{@worker_pid}'"
        logger.error msg
        raise $ERROR_INFO, msg, $ERROR_INFO.backtrace
      end
    end
  end


  before do
    TestWorker.enqueue(message.to_json)
  end

  it "does something" do
    sleep 1
    puts "working hard for the money"
  end
end
