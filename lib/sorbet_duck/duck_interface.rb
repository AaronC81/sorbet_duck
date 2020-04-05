# typed: ignore

require 'parlour'

module SorbetDuck
  DuckInterface = Struct.new(:interface_name, :method_rbi_object) do
    def add_definition_to_namespace(namespace)
      namespace.create_module('Duck').create_module(interface_name, interface: true) do |mod|
        mod.create_extends(['T::Helpers', 'T::Sig'])
        mod.children << method_rbi_object
      end
    end

    def implement_for_class(namespace, class_name)
      namespace.create_class(class_name) do |cls|
        cls.create_include("Duck::#{interface_name}")
      end
    end
  end
end
