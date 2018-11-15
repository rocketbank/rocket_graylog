lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rocket_graylog/version"

Gem::Specification.new do |spec|
  spec.name          = "rocket_graylog"
  spec.version       = RocketGraylog::VERSION
  spec.authors       = ["pechorin"]
  spec.email         = ["pechorin.andrey@gmail.com"]

  spec.summary       = %q{Safe async wrapper for Graylog}
  spec.description   = %q{Safe async wrapper for Graylog}
  spec.homepage      = "http://github.com/rocketbank/rocket_graylog"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"

  spec.add_dependency "gelf", ">= 3.0.0"
  spec.add_dependency "retriable", ">= 3.1.0"
  spec.add_dependency "concurrent-ruby", ">= 1.0.5"
end
