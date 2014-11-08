# encoding: UTF-8

require 'spec_helper'
require 'tempfile'
require 'yaml'
require 'commander'

describe Factor::Commands::Command do
  before :each do
    @command = Factor::Commands::Command.new
  end

  output_methods = %w(info warn error success)

  output_methods.each do |method_name|
    describe ".#{method_name}" do
      it "logs #{method_name}" do

        test_string = 'Hello World'
        output = capture_stdout do
          @command.logger.method(method_name.to_sym).call message: test_string
        end

        expect(output).to include(test_string)
        expect(output).to include(method_name.upcase)
      end
    end
  end

  describe '.exception' do
    it 'logs exception' do

      test_string = 'Hello World'
      exception_string = 'Something be busted'
      output = capture_stdout do
        begin
          fail ArgumentError, exception_string
        rescue => ex
          @command.logger.error message: test_string, exception:ex
        end
      end

      expect(output).to include(test_string)
      expect(output).to include(exception_string)
      expect(output).to include('ERROR')

    end
  end

  describe '.load_config' do
    it 'can load credentials and connectors' do
      credentials_file = Tempfile.new('credentials')
      connectors_file = Tempfile.new('connectors')

      credentials_content = {
        'github' => {
          'api_key' => 'fake_github_key'
        },
        'heroku' => {
          'api_key' => 'fake_heroku_key'
        }
      }

      connectors_content = {
        'timer'   => 'http://localhost:9294/v0.4/timer',
        'web'     => 'http://localhost:9294/v0.4/web',
        'github'  => 'http://localhost:9294/v0.4/github',
        'heroku'  => 'http://localhost:9294/v0.4/heroku'
      }

      credentials_file.write(YAML.dump(credentials_content))
      connectors_file.write(YAML.dump(connectors_content))

      credentials_file.rewind
      connectors_file.rewind

      options = Commander::Command::Options.new
      options.credentials = credentials_file.path
      options.connectors  = connectors_file.path

      config_settings = {
        credentials: options.credentials,
        connectors:  options.connectors
      }

      output = capture_stdout do
        @command.load_config config_settings
      end

      expect(configatron.credentials.github.api_key).to eq('fake_github_key')
      expect(configatron.credentials.heroku.api_key).to eq('fake_heroku_key')
      connectors_content.keys.each do |expected_connector_key|
        actual_connector   = configatron.connectors[expected_connector_key]
        expected_connector = connectors_content[expected_connector_key]
        expect(actual_connector).to eq(expected_connector)
      end

      credentials_file.close
      connectors_file.close
    end
  end
end
