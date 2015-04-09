# encoding: UTF-8

require 'spec_helper'
require 'tempfile'
require 'yaml'
require 'commander'
require 'factor/commands/base'

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
          raise ArgumentError, exception_string
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
    it 'can load credentials' do
      credentials_file = Tempfile.new('credentials')

      credentials_content = {
        'github' => {
          'api_key' => 'fake_github_key'
        },
        'heroku' => {
          'api_key' => 'fake_heroku_key'
        }
      }

      credentials_file.write(YAML.dump(credentials_content))
      credentials_file.rewind
      options             = Commander::Command::Options.new
      options.credentials = credentials_file.path
      config_settings     = {
        credentials: options.credentials,
      }

      output = capture_stdout do
        @command.load_config config_settings
      end

      expect(configatron.credentials.github.api_key).to eq('fake_github_key')
      expect(configatron.credentials.heroku.api_key).to eq('fake_heroku_key')

      credentials_file.close
    end
  end
end
