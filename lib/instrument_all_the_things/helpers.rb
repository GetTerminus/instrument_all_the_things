# frozen_string_literal: true

require_relative './method_proxy'
require_relative './context'

module InstrumentAllTheThings
  module Helpers
    module ClassMethods
      def instrument(**kwargs)
        @last_settings = kwargs
      end

      def _conscript_last_iatt_settings
        @last_settings.tap { @last_settings = nil }
      end

      def singleton_method_added(method_name)
        settings = _conscript_last_iatt_settings

        return unless settings

        settings[:context] = Context.new(
          method_name: method_name,
          instance: false,
        )

        InstrumentAllTheThings::MethodProxy
          .for_class(singleton_class)
          .wrap_implementation(method_name, settings)
        super
      end

      def method_added(method_name)
        settings = _conscript_last_iatt_settings

        return unless settings

        settings[:context] = Context.new(
          method_name: method_name,
          instance: true,
        )

        InstrumentAllTheThings::MethodProxy
          .for_class(self)
          .wrap_implementation(method_name, settings)

        super
      end
    end

    def self.included(other_class)
      other_class.extend(ClassMethods)

      InstrumentAllTheThings::MethodProxy.for_class(other_class)
      InstrumentAllTheThings::MethodProxy.for_class(other_class.singleton_class)
    end
  end
end
