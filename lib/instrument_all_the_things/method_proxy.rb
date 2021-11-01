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

      def set_context_tags(klass, settings, args, kwargs)
        return unless settings.is_a?(Hash) && settings[:trace].is_a?(Hash) && settings[:trace][:tags]

        settings[:context][:tags] = settings[:trace][:tags].map do |tag|
          if tag.is_a?(Proc)
            case tag.arity
            when 2
              tag.call(args, kwargs)
            when 1
              tag.parameters[0][1].to_s == 'args' ? tag.call(args) : tag.call(kwargs)
            else
              klass.instance_exec(&tag)
            end
          else
            tag
          end
        rescue StandardError
          nil
        end.compact
      end

      def wrap_implementation(method_name, settings)
        wrap = MethodInstrumentor.new(**settings)
        set_tags = method(:set_context_tags)

        define_method(method_name) do |*args, **kwargs, &blk|
          set_tags.call(self, settings, args, kwargs)
          wrap.invoke(klass: is_a?(Class) ? self : self.class) do
            super(*args, **kwargs, &blk)
          end
        end
      end
    end
  end
end
