# frozen_string_literal: true

require_relative './method_proxy'
require_relative './context'

module InstrumentAllTheThings
  module Helpers
    module ClassMethods
      def instrument(trace: true)
        @last_settings = {
          trace: trace
        }
      end

      def method_added(method_name)
        return unless @last_settings

        settings = @last_settings
        @last_settings = nil

        settings[:context] = Context.new(
          klass: self,
          method_name: method_name,
          instance: true
        )

        InstrumentAllTheThings::MethodProxy
          .for_class(self)
          .wrap_implementation(method_name, settings)
      end
    end

    def self.included(other_class)
      other_class.extend(ClassMethods)
    end
  end
end
