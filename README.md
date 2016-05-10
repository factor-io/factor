![Factor.io Logo](/factor.png)

[![Code Climate](https://codeclimate.com/github/factor-io/factor.png)](https://codeclimate.com/github/factor-io/factor)
[![Coverage Status](https://coveralls.io/repos/github/factor-io/factor/badge.svg?branch=master)](https://coveralls.io/github/factor-io/factor?branch=master)
[![Dependency Status](https://gemnasium.com/factor-io/factor.svg)](https://gemnasium.com/factor-io/factor)
[![Build Status](https://travis-ci.org/factor-io/factor.svg)](https://travis-ci.org/factor-io/factor)
[![Gem Version](https://badge.fury.io/rb/factor.svg)](http://badge.fury.io/rb/factor)
[![Inline docs](http://inch-ci.org/github/factor-io/factor.svg?branch=master)](http://inch-ci.org/github/factor-io/factor)

## What is Factor.io?
Factor.io a Ruby-based DSL for defining and running workflows connecting popular developer tools and services. It is designed to run from the command line, run locally without other service dependencies, very easily extensible, and workflow definitions are stored in files so they can be checked into your project repos. Workflows can run tasks on various tools and services (e.g. create a Github issue, post to Slack, make a HTTP POST call), and they can listen for events too (e.g. listen for a pattern in Slack, open a web hook, or listen for a git push on a branch in Github). Lastly, it supports great concurrency control so you can run many tasks in parallel and aggregate the results.

## Install and Setup
This is a gem with a command line interface `factor`. To install:

    gem install factor

## Basic Usage
First, we need to install the dependencies (via Bundler). 

**Gemfile**:
```
source "https://rubygems.org"

# Using code from Github for latest (as opposed to RubyGems).
gem 'factor', git: 'https://github.com/factor-io/factor.git'
gem 'factor-connector-web', git: 'https://github.com/factor-io/connector-web.git'
```

In a new project directory create a new file `workflow.rb` like this:

**workflow.rb**:
```ruby
require 'factor-connector-web'

web_hook = run 'web::hook'

web_hook.on(:trigger) do |post_info|
  if post_info[:configured]
    success 'Configured and listening on...'
    success post_info[:configured][:url]
  else
    info post_info
  end
end

web_hook.on(:log) do |log_info|
  debug log_info[:message]
end

web_hook.execute
web_hook.wait
```

Now run this from the command line:
```
bundle install
bundle exec factor w workflow.rb
```

## Next

- [Workflow Syntax](https://github.com/factor-io/factor/wiki/Workflow-Syntax): Factor.io workflows can do all sorts of magic, like running in parallel, aggregating command results, defining sequences, error handling, and more.
- [Connectors](https://github.com/factor-io/factor/wiki/Connectors): These are the officially support Connectors (integrations).
- [Custom Connectors](https://github.com/factor-io/factor/wiki/Creating-a-custom-connector): A guide for creating a custom Connector.
- [More examples](https://github.com/factor-io/example-workflows): This repo contains a library of examples that demonstrate all the Factor.io workflow syntax capabilities as well as the officially supported Conenctors.
