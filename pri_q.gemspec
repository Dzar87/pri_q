# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pri_q/version'

Gem::Specification.new do |spec|
  spec.name          = "pri_q"
  spec.version       = PriQ::VERSION
  spec.date          = Date.today.to_s
  spec.authors       = ["Dzar87"]
  spec.email         = ["omgitsdzar@gmail.com"]

  spec.summary       = %q{Thread safe priority queue using a binary heap}
  spec.description   = %q{Based on Brian Schroeder's PriorityQueue 0.1.2. Simplified and made thread safe by mimicing the structure of Queue.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|.idea)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

end
