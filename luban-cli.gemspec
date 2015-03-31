# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'luban/cli/version'

Gem::Specification.new do |spec|
  spec.name          = "luban-cli"
  spec.version       = Luban::CLI::VERSION
  spec.authors       = ["Rubyist Chi"]
  spec.email         = ["rubyist.chi@gmail.com"]
  spec.description   = %q{Command-line interface for Ruby}
  spec.summary       = %q{Luban::CLI is a command-line interface for Ruby with a simple lightweight option parser and command handler based on Ruby standard library, OptionParser}
  spec.homepage      = "https://github.com/lubanrb/cli"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
