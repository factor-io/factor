require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

# RSpec::Core::RakeTask.new(:spec)
desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.verbose = false
  t.rspec_opts = '--color --order random'
end

task :default => :spec