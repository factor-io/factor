[![Code Climate](https://codeclimate.com/github/factor-io/factor.png)](https://codeclimate.com/github/factor-io/factor)
[![Test Coverage](https://codeclimate.com/github/factor-io/factor/coverage.png)](https://codeclimate.com/github/factor-io/factor)
[![Dependency Status](https://gemnasium.com/factor-io/factor.svg)](https://gemnasium.com/factor-io/factor)
[![Build Status](https://travis-ci.org/factor-io/factor.svg)](https://travis-ci.org/factor-io/factor)
[![Gem Version](https://badge.fury.io/rb/factor.svg)](http://badge.fury.io/rb/factor)

Factor.io Server Runtime
==========
This is the runtime that enables you to run workflows.

## Install and Setup
This is a gem with a command line interface `factor`. To install:

    gem install factor

## Usage
To get started you will need three files, `connectors.yml`, `credentials.yml`, and `basic-workflow.rb`, or you can just start with the example workflow directory...

    git clone git@github.com/factor-io/example-workflows.git
    cd example-workflows

now start the server:

    factor s
