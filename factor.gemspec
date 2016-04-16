# encoding: UTF-8
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'factor/version'

Gem::Specification.new do |s|
  s.name          = 'factor'
  s.version       = Factor::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Maciej Skierkowski']
  s.email         = ['maciej@factor.io']
  s.homepage      = 'https://factor.io'
  s.summary       = 'CLI and Library for Factor.io runtime'
  s.description   = 'This is the core of the Factor.io Runtime. The library contains the DSL for defining connectors (plugsin) and workflows. The command line tool can be used to run those workflows'
  s.files         = Dir.glob('lib/**/*.rb')
  s.license       = "MIT"

  s.test_files    = Dir.glob("./{test,spec,features}/*.rb")
  s.executables   = ['factor']
  s.require_paths = ['lib']

  s.add_runtime_dependency 'commander', '~> 4.4.0'
  s.add_runtime_dependency 'rainbow', '~> 2.1.0'
  s.add_runtime_dependency 'configatron', '~> 4.5.0'
  s.add_runtime_dependency 'concurrent-ruby', '~> 1.0.1'
  s.add_development_dependency 'coveralls', '~> 0.8.13'
  s.add_development_dependency 'rake', '~> 11.1.2'
  s.add_development_dependency 'guard', '~> 2.13.0'
  s.add_development_dependency 'guard-rspec', '~> 4.6.5'
end
