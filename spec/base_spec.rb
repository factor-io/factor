require 'spec_helper'

require 'commands/base'

module Factor::Commands
  describe Command do
    before :each do
      @command = Factor::Commands::Command.new
    end

    output_methods=%w(info warn error success)

    output_methods.each do |method_name|
      describe ".#{method_name}" do
        it "logs #{method_name}" do
          
          test_string='Hello World'
          output = capture_stdout do
            @command.method(method_name.to_sym).call message:test_string
          end
          
          expect(output).to include(test_string)
          expect(output).to include(method_name.upcase)
        end
      end
    end

    describe ".exception" do
      it "logs exception" do

        test_string = 'Hello World'
        exception_string = 'Something be busted'
        output = capture_stdout do
          begin
            raise ArgumentError, exception_string
          rescue => ex
            @command.exception test_string, ex
          end
        end

        expect(output).to include(test_string)
        expect(output).to include(exception_string)
        expect(output).to include("ERROR")

      end
    end

    describe '.load_config' do
      it "can load credentials and connectors" do
        
      end
    end
  end
end