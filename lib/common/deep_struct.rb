require 'ostruct'

module Factor
  module Common
    class DeepStruct < OpenStruct
      def initialize(hash=nil)
        @table = {}
        @hash_table = {}

        if hash
          hash.each do |k,v|
            @table[k.to_sym] = (v.is_a?(Hash) ? self.class.new(v) : v)
            @hash_table[k.to_sym] = v

            new_ostruct_member(k)
          end
        end
      end

      def to_h
        @hash_table
      end

      def to_s
        @hash_table.to_s
      end

      def inspect
        @hash_table.inspect
      end

      def [](idx)
        hash = marshal_dump
        hash[idx.to_sym]
      end
    end

    def self.flat_hash(h,f=[],g={})
      return g.update({ f=>h }) unless h.is_a? Hash
      h.each { |k,r| flat_hash(r,f+[k],g) }
      g
    end

    def self.simple_object_convert(item)
      if item.is_a?(Hash)
        Factor::Common::DeepStruct.new(item)
      elsif item.is_a?(Array)
        item.map do |i|
          simple_object_convert(i)
        end
      else
        item
      end
    end
  end
end