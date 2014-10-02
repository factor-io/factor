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

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map do |f|
    File.basename(f)
  end
  s.require_paths = ['lib']

  s.add_runtime_dependency 'commander', '~> 4.2.1'
  s.add_runtime_dependency 'rest_client', '~> 1.7.3'
  s.add_runtime_dependency 'faye-websocket', '~> 0.7.4'
  s.add_runtime_dependency 'colored', '~> 1.2'
  s.add_runtime_dependency 'configatron', '~> 4.2.0'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 0.4.1'
  s.add_development_dependency 'rspec', '~> 3.1.0'
  s.add_development_dependency 'rake', '~> 10.3.2'
end
