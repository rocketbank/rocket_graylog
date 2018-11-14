require 'concurrent'
require 'retriable'
require "gelf"

class AsyncGraylogSender

  # should be compatible with Concurrent::Async interface
  class TestQueue < Array
    def async 
      self
    end

    def send_message(message, options = {})
      self << [message, options]
    end
  end

  include Concurrent::Async

  attr_accessor :test_mode, 
                :async_mode,
                :facility,
                :protocol, # :tcp/:upd
                :host,
                :port,
                :graylog_errors,
                :retry_on_host_errors,
                :send_timeout,
                :error_hook,
                :debug
  
  def initialize(test_mode: nil, async_mode: true, facility: 'APP', protocol: :tcp, host: 'localhost', port: 5514)
    @test_mode = if test_mode.is_a?(TrueClass) || test_mode.is_a?(FalseClass)
      test_mode
    else
      if defined?(Rails) and Rails.respond_to?(:env)
        Rails.env.test?
      else
        false
      end
    end

    @async_mode     = async_mode
    @facility       = facility
    @protocol       = protocol
    @host           = host
    @port           = port
    @graylog_errors = false

    unless @protocol == :tcp || @protocol == :udp
      raise RuntimeError, "Invalid protocol => #{@protocol.inspect}"
    end
  end

  def queue
    if @test_mode 
      @test_queue ||= TestQueue.new
    else
      self
    end
  end

  def notify(message, options = {})
    options[:timestamp] ||= Time.now.utc.to_f

    if @async_mode == true
      queue.async.send_message(message, options)
    else
      queue.send_message(message, options)
    end
  end

  def send_message(message, options = {})
    do_request = lambda do
      if @send_timeout
        Timeout::timeout(@send_timeout) do
          gelf_instance.notify!(options.merge short_message: message)
        end
      else
        gelf_instance.notify!(options.merge short_message: message)
      end
    end

    if @retry_on_host_errors.is_a?(Hash)
      Retriable.retriable(@retry_on_host_errors) do
        do_request.call
      end
    else
      do_request.call
    end
  rescue StandardError => error
    @error_hook.call(error) if @error_hook

    if @graylog_errors == true
      raise
    end
  end

  def clear_test_queue!
    queue.clear if queue.is_a?(TestQueue)
  end

  private def gelf_instance
    @gelf ||= GELF::Notifier.new(@host, @port, "LAN", { 
      facility: @facility, 
      protocol: gelf_protocol
    })
  end

  private def gelf_protocol
    if @protocol == :tcp
      GELF::Protocol::TCP
    else
      GELF::Protocol::UDP
    end
  end

end
