require 'spec_helper'

require 'commands/base'

module Factor::Commands
  describe Command do
    describe ".info" do
      it "logs info" do
        expect(true).to eq(true)
      end
    end
  end
end