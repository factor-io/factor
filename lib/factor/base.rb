# encoding: UTF-8

# Primary Factor.io module
module Factor

  String.send :define_method, :classify do
    self.split('_').collect! { |w| w.capitalize }.join
  end

  String.send :define_method, :underscore do
    self.gsub(/::/, '/')
    .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
    .gsub(/([a-z\d])([A-Z])/, '\1_\2')
    .tr('-', '_')
    .downcase
  end
end