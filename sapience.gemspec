# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sapience/version"

Gem::Specification.new do |spec|
  spec.name          = "sapience"
  spec.version       = Sapience::VERSION
  spec.authors       = ["Mikael Henriksson", "Alex Malkov"]
  spec.email         = ["mika@reevoo.com", "alex.malkov@reevoo.com"]

  spec.summary       = "Write a short summary, because Rubygems requires one."
  spec.description   = "Write a longer description or delete this line."
  spec.homepage      = "https://sapience.github.io"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "Set to 'http://mygemserver.com'"
  else
    fail "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(/^(test|spec|features)\//) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "concurrent-ruby"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "reevoocop"
  spec.add_development_dependency "fuubar"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-json"
  spec.add_development_dependency "rspec-its"
end
