# RocketGraylog

Safe for production async wrapper around GELF & Graylog 

## Features

- async send messages with concurrent-ruby actor
- slow block execution notification
- all internal errors supressed by default (but you can turn it on)
- retry politics with Retriable gem
- custom _topic with method_missing
- test-ready

## Rails configuration

Gemfile:

currently install available only through github:
```ruby
gem 'rocket_graylog', github: 'https://github.com/rocketbank/rocket_graylog.git'
```

create `config/initializers/rocket_graylog.rb` with content:

```ruby 
RocketGraylog.configure do |cfg|
  cfg.facility    = "APPLICATION"
  cfg.host        = ENV["GRAYLOG"]
  cfg.port        = 5514
  cfg.protocol    = :tcp # :upd

  # raise errors on graylog host errors 
  # false means errors will be supressed and do not affect application
  # but message will be lost
  cfg.graylog_errors = false 

  # retry on graylog host errors, just provide options for Retriable 
  cfg.retry_on_host_errors = {
    :on => [Timeout::Error, Errno::ECONNREFUSED], :tries => 3
  }

  # uncomment to disable message send retring
  # cfg.retry_on_host_errors = nil

  # timeout for sending message to Gelf 
  cfg.send_timeout = 0.5

  # provide block for error notifications
  # cfg.error_hook = lambda do |error|
  #   Honeybadger.notify(error)
  # end

  cfg.test_mode = Rails.env.test?
end
```

Rails logging `config/environments/production.rb`:

```ruby
Rails.application.configure do
  gelf = GELF::Logger.new(ENV['GRAYLOG'], 5514, "LAN", { :facility => "APPLICATION", :protocol => GELF::Protocol::UDP })
  gelf.rescue_network_errors = true
  config.logger = gelf
end
```

## Usage

send event
```ruby
RocketGraylog.notify("message", { :a => 100 })
```

send event with _topic: 'alerts'
```ruby
RocketGraylog.notify_alerts("message")
```

notify if block time execution exceed threshold (10 seconds by default)
```ruby
RocketGraylog.long_execution_detector(name: 'my_tag', threshold: 100.seconds) do
  sleep(101)
end
```

tests/specs:
```ruby
before(:each) do
  RocketGraylog.clear_test_queue!
end

it '...' do
  expect(RocketGraylog.queue.size).to eq(1)
  # ...
end
```

handy alias

```ruby
Graylog.notify("test log message")
```
