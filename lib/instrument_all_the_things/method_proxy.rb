# frozen_string_literal: true

require_relative './method_instrumentor'

module InstrumentAllTheThings
  module MethodProxy
    def self.for_class(klass)
      find_for_class(klass) || install_on_class(klass)
    end

    def self.find_for_class(klass)
      klass.ancestors.detect do |a|
        a.is_a?(Instrumentor) &&
          a._iatt_built_for == klass
      end
    end

    def self.install_on_class(klass)
      construct_for_class(klass).tap do |m|
        klass.prepend(m)
      end
    end

    def self.construct_for_class(klass)
      Module.new do
        extend Instrumentor
      end.tap { |m| m._iatt_built_for = klass }
    end

    module Instrumentor
      def inspect
        "InstrumentAllTheThings::#{@_iatt_built_for}Proxy"
      end

      def _iatt_built_for
        @_iatt_built_for
      end

      def _iatt_built_for=(val)
        @_iatt_built_for = val
      end

      def wrap_implementation(method_name, settings)
        wrap = MethodInstrumentor.new(**settings)

        define_method(method_name) do |*args, **kwargs, &blk|
          wrap.invoke(klass: is_a?(Class) ? self : self.class) do
            if settings.dig(:trace, :tags)
              settings[:context][:tags] = settings[:trace][:tags].map { |tag| tag.is_a?(Proc) ? instance_exec(&tag) : tag }
            end
            
            super(*args, **kwargs, &blk)
          end
        end
      end
    end
  end
end
