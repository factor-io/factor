require 'commands/base'
require 'spec_helper'

module Factor::Commands
  describe Command do
    describe ".info" do
      it "logs info" do
        expect(true).to eq(true)
      end
    end
  end
end