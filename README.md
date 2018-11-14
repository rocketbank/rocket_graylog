# RocketGraylog

Safe for production async wrapper around GELF & Graylog 

## Features

- async send messages with concurrent-ruby actor
- custom _topic with method_missing
- all internal errors supressed by default (but you can turn it on)
- retry politics with Retriable gem
- test-ready

## Rails configuration

Gemfile:

```ruby
gem 'rocket_graylog', github: 'rocketbank/rocket_graylog'
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
  cfg.error_hook = lambda do |error|
    Honeybadger.notify(error)
  end

  cfg.test_mode   = Rails.env.test?
end
```

## Usage

send event
```ruby
RocketGraylog.notify("message", { :a => 100 })
```

send event with _topic: 'finmon'
```ruby
RocketGraylog.notify_finmon("message")
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
