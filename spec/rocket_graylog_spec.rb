RSpec.describe RocketGraylog do

  before do
    RocketGraylog.configure do |config| 
      config.test_mode = true
      config.error_hook = nil
    end
  end

  after :each do
    RocketGraylog.clear_test_queue!
  end

  it "has Graylog alias" do
    expect(Graylog).to eq(RocketGraylog)
  end

  it "has async sender initialized" do
    expect(RocketGraylog.sender).to be_a(AsyncGraylogSender)
  end

  it "enqueue messages in test queue in test mode" do
    msg = "test"

    expect(RocketGraylog.queue).to be_a(AsyncGraylogSender::TestQueue)

    RocketGraylog.notify(msg)

    expect(RocketGraylog.queue.size).to eq(1)

    message, options = RocketGraylog.queue.first
    expect(message).to eq(msg)
    expect(options.keys.include?(:timestamp)).to eq(true)
  end

  context "method_missing" do

    it "enqueue messages with _topic extracted from method_missing" do
      msg = "contexted"
      RocketGraylog.notify_test_env(msg)

      message, options = RocketGraylog.queue.first
      expect(message).to eq(msg)

      expect(options.keys.include?(:_topic)).to eq(true)
      expect(options[:_topic]).to eq('test_env')
    end

  end

  context "production mode" do

    before(:each) do
      RocketGraylog.configure { |config| config.test_mode = false }
    end

    after(:each) do
      RocketGraylog.configure { |config| config.test_mode = true }
    end

    # test on failed on first connection
    it "calls GELF as transport with options" do
      RocketGraylog.configure do |config| 
        config.async_mode = false
        config.graylog_errors = false
      end

      expect(RocketGraylog.sender.test_mode).to eq(false)
      expect(RocketGraylog.sender.async_mode).to eq(false)
      expect(RocketGraylog.queue).to be_a(AsyncGraylogSender)

      expect { RocketGraylog.notify("real message") }.not_to raise_error(StandardError)

      errors_counter = 0

      RocketGraylog.configure do |config| 
        config.host = "not exists"
        config.port = "not exists"
        config.graylog_errors = true
        config.error_hook = lambda do |error|
          errors_counter += 1
        end
      end

      expect { RocketGraylog.notify("real message") }.to raise_error(SocketError)
      expect(errors_counter).to eq(1)
    end

  end


end
