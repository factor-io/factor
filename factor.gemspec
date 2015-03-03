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
  s.summary       = 'CLI to manager workflows on Factor.io'
  s.description   = 'CLI to manager workflows on Factor.io'
  s.files         = Dir.glob('lib/**/*.rb')

  s.test_files    = Dir.glob("./{test,spec,features}/*.rb")
  s.executables   = ['factor']
  s.require_paths = ['lib']

  s.add_runtime_dependency 'commander', '~> 4.3.0'
  s.add_runtime_dependency 'colored', '~> 1.2'
  s.add_runtime_dependency 'configatron', '~> 4.5.0'
  s.add_runtime_dependency 'rest-client', '~> 1.7.3'
  s.add_runtime_dependency 'liquid', '~> 3.0.1'
  s.add_runtime_dependency 'factor-connector-api', '~> 0.0.14'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 0.4.7'
  s.add_development_dependency 'rspec', '~> 3.2.0'
  s.add_development_dependency 'rake', '~> 10.4.2'
end
