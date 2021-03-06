# frozen_string_literal: true
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sapience/version"

Gem::Specification.new do |spec|
  spec.name          = "sapience"
  spec.version       = Sapience::VERSION
  spec.authors       = ["Mikael Henriksson", "Alex Malkov"]
  spec.email         = ["mika@reevoo.com", "alex.malkov@reevoo.com"]

  spec.summary       = "Hasslefree autoconfiguration for logging, metrics and exception collection."
  spec.description   = "Hasslefree autoconfiguration for logging, metrics and exception collection."
  spec.homepage      = "https://github.com/reevoo/sapience-rb"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    fail "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(/^(test|test_apps|spec|features|bin)\//) }
  spec.require_paths = ["lib"]

  spec.add_dependency "concurrent-ruby", "~> 1.0"
  spec.add_development_dependency "active_model_serializers", "~> 0.10.0"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "bundler", "~> 1.17.3"
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency "dogstatsd-ruby", "~> 5.2.0"
  spec.add_development_dependency "fuubar"
  spec.add_development_dependency "gem-release"
  spec.add_development_dependency "grape"
  spec.add_development_dependency "memory_profiler"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "rails", "~> 5.0.0.1"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "reevoocop"
  spec.add_development_dependency "rspec", "~> 3.10.0"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "rspec-prof"
  spec.add_development_dependency "sentry-raven", "~> 3.1.2"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-json"
end
