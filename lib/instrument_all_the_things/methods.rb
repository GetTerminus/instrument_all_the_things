require 'active_support/core_ext/string/inflections'

module InstrumentAllTheThings
  module Methods
    class IntrumentedMethod
      include HelperMethods

      attr_accessor :meth, :options, :klass, :type

      def initialize(meth, options, klass, type)
        self.meth = meth
        self.options = options
        self.klass = klass
        self.type = type
      end

      def call(context, args, &blk)
        with_tags(tags_for_method(args)) do
          increment("#{instrumentation_key(context)}.count")
          _run_instrumented_method(context, args, &blk)
        end
      end

      def tags_for_method(args)
        [
          "method:#{_naming_for_method(meth)}",
          "method_class:#{normalize_class_name(self.klass)}"
        ].concat(user_defined_tags(args))
      end

      def user_defined_tags(args)
        if options[:tags].respond_to?(:call)
          if options[:tags].arity.zero?
            options[:tags].call
          else
            options[:tags].call(*args)
          end
        elsif options[:tags].is_a?(Array)
          options[:tags]
        else
          []
        end
      end

      def _run_instrumented_method(context, args, &blk)
        time("#{instrumentation_key(context)}.timing") do
          capture_exception(as: instrumentation_key(context)) do
            context.send("_#{meth}_without_instrumentation", *args, &blk)
          end
        end
      rescue => e
        raise InstrumentAllTheThings::ExceptionHandler.register(e)
      end

      def instrumentation_key(context)
        as = options[:as]
        prefix = options[:prefix]
        key = nil
        if as.respond_to?(:call)
          if as.arity == 0
            key = as.call
          else
            key = as.call(context)
          end
        elsif as
          key = as
        else
          key = [context.base_instrumentation_key, self.type, meth].join('.')
        end

        if prefix
          "#{prefix}.#{key}"
        else
          key
        end
      end

      def _naming_for_method(meth)
        if self.type == :instance
          "##{meth}"
        else
          ".#{meth}"
        end
      end
    end

    def self.included(other_klass)
      other_klass.extend(ClassMethods)
      other_klass.include(HelperMethods)
    end

    def base_instrumentation_key
      self.class.base_instrumentation_key
    end

    module ClassMethods
      include HelperMethods

      def base_instrumentation_key
        to_s.underscore.tr('/','.')
      end

      def instrument(options = {})
        @options_for_next_method = options
      end

      def _instrumentors
        @_instrumentors ||= {}
      end

      def method_added(meth)
        return unless @options_for_next_method

        options = @options_for_next_method
        @options_for_next_method = nil

        alias_method "_#{meth}_without_instrumentation", meth

        _instrumentors["##{meth}"] = IntrumentedMethod.new(meth, options, self, :instance)
        instrumentor = _instrumentors["##{meth}"]

        define_method(meth) do |*args, &blk|
          instrumentor.call(self, args, &blk)
        end
      end

      def singleton_method_added(meth)
        return unless @options_for_next_method

        options = @options_for_next_method
        @options_for_next_method = nil

        define_singleton_method("_#{meth}_without_instrumentation", method(meth))

        _instrumentors[".#{meth}"] = IntrumentedMethod.new(meth, options, self, :class)
        instrumentor = _instrumentors[".#{meth}"]

        define_singleton_method(meth) do |*args, &blk|
          instrumentor.call(self, args, &blk)
        end
      end
    end
  end
end
