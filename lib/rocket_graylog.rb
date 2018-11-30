require "rocket_graylog/version"
require "rocket_graylog/async_graylog_sender"

module RocketGraylog

  @@sender = AsyncGraylogSender.new

  def self.configure
    return unless block_given?

    yield @@sender
  end

  def self.notify(message, options = {})
    if message == nil || message == ""
      return
    end

    !!@@sender.notify(message, options)
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

  # Notify on slow block execution
  #
  # name: name of event
  # context: context to which will be provided with log
  # threshold: in seconds
  def self.long_execution_detector(name: nil, context: nil, threshold: 10, &block)
    return unless block_given? 

    start        = Time.now.to_f
    block_result = block.call
    finish       = Time.now.to_f

    cost = (finish - start).round(3)

    if threshold.is_a?(Numeric) && cost >= threshold
      keys = ["long_execution_detector"]
      keys << "long_execution_detector_#{name}" if name
      keys = keys.join(' ')

      params = {}
      params[:context] = context if context

      self.notify("#{keys} cost:#{cost} threshold:#{threshold}", params)
    end

    block_result
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

    options.merge(full_message: options[:context]) if !options[:full_message] && options[:context]

    notify message, options.merge(_topic: method_name.to_s.match(/^notify_(\S+)/)[1])
  end

end

# for compability with rocket codebase
Graylog = RocketGraylog
