module Factor
  module Connector
    module Registry

      def self.get(id)
        get_class = self.class.constants.find do |class_name|
          begin
            class_obj = self.class.const_get(class_name)
            class_obj.superclass == Factor::Connector::Definition && class_obj.new.id == id
          rescue
          end
        end
        raise "No definition found with id #{id}" unless get_class
        self.class.const_get(get_class).new
      end
    end
  end
end