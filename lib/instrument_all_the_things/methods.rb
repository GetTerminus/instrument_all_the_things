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
          increment("methods.count")
          _run_instrumented_method(context, args, &blk)
        end
      end

      def tags_for_method(args)
        [
          "method:#{_naming_for_method(meth)}",
          "method_class:#{normalize_class_name(self.klass.class)}"
        ].tap do |arr|
          if options[:tags].respond_to?(:call)
            if options[:tags].arity.zero?
              arr.concat(options[:tags].call)
            else
              arr.concat(options[:tags].call(*args))
            end
          elsif options[:tags].is_a?(Array)
            arr.concat(options[:tags])
          end
        end
      end

      def _run_instrumented_method(context, args, &blk)
        time("methods.timing") do
          capture_exception do
            context.send("_#{meth}_without_instrumentation", *args, &blk)
          end
        end
      rescue => e
        raise InstrumentAllTheThings::ExceptionHandler.register(e)
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
    end

    module ClassMethods
      include HelperMethods

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

        _instrumentors[".#{meth}"] = IntrumentedMethod.new(meth, options, self, :instance)
        instrumentor = _instrumentors[".#{meth}"]

        define_singleton_method(meth) do |*args, &blk|
          instrumentor.call(self, args, &blk)
        end
      end
    end
  end
end
