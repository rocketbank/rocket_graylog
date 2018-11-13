require "rocket_graylog/version"
require "rocket_graylog/async_graylog_sender"
require "gelf"

module RocketGraylog

  @@sender = AsyncGraylogSender.new

  def self.configure
    return unless block_given?

    yield @@sender
  end

  def self.notify(message, options = {})
    @@sender.notify(message, options)
  end

  def self.sender
    @@sender
  end

  def self.queue
    @@sender and @@sender.queue
  end

  # for compability with old specs
  def self.test_queue
    self.queue
  end

  def self.clear_test_queue!
    @@sender and @@sender.clear_test_queue!
  end

  def self.method_missing(method_name, *args)
    super unless method_name.to_s.start_with? 'notify_'
    message, options = args
    options ||= {}
    options.each_pair do |k, v|
      unless v.is_a?(Numeric) || v.is_a?(String) || k == :context
        options[k] = v.inspect
      end
    end

    options.merge(full_message: options[:context].pretty_inspect) if !options[:full_message] && options[:context]

    notify message, options.merge(_topic: method_name.to_s.match(/^notify_(\S+)/)[1])
  end

end

# for compability with rocket codebase
Graylog = RocketGraylog
