module Factor
  module Common
    module Blocker

      def self.block_until(options = {}, &block)
        pause = options[:sleep] || 0.1

        begin
          continue = block.yield
          sleep pause
        end while !continue
      end

      def self.block_until_interrupt_or(options = {}, &block)
        pause = options[:sleep] || 0.1
        interrupted = false

        Thread.new do 
          block_until_interrupt
          interrupted = true
        end
        
        begin
          until_met = block.yield
          begin
            sleep pause
          rescue Interrupt
            interrupted = true
          end
          stop_looping = until_met || interrupted
        end until stop_looping
      end

      def self.block_until_interrupt
        begin
          begin
            sleep 0.1
          end while true
        rescue Interrupt
        end
      end
    end
  end
end