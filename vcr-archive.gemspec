# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vcr/archive/version'

Gem::Specification.new do |spec|
  spec.name          = 'vcr-archive'
  spec.version       = VCR::Archive::VERSION
  spec.authors       = ['Chris Mytton']
  spec.email         = ['chrismytton@gmail.com']

  spec.summary       = 'VCR Serializer and Persister for archiving HTTP requests'
  spec.homepage      = 'https://github.com/everypolitician/vcr-archive'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'vcr', '~> 3.0.2'
  spec.add_runtime_dependency 'webmock', '~> 2.0.3'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry', '~> 0.10.4'
end
