module InstrumentAllTheThings
  module Methods
    include HelperMethods

    def self.included(other_klass)
      other_klass.extend(ClassMethods)
    end

    def _tags_for_method(meth, options, args)
      [
        "method:#{_naming_for_method(meth)}",
        "method_class:#{normalize_class_name(self.class)}"
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

    def _instrument_method(meth, args, options, &blk)
      with_tags(_tags_for_method(meth, options, args)) do
        increment("methods.count")
        _run_instrumented_method(meth, args, options, &blk)
      end
    end

    def _run_instrumented_method(meth, args, options, &blk)
      time("methods.timing") do
        capture_exception do
          self.send("_#{meth}_without_instrumentation", *args, &blk)
        end
      end
    rescue => e
      raise InstrumentAllTheThings::Exception.register(e)
    end

    def _naming_for_method(meth)
      "##{meth}"
    end

    module ClassMethods
      include HelperMethods

      def instrument(options = {})
        @options_for_next_method = options
      end

      def method_added(meth)
        return unless @options_for_next_method

        options = @options_for_next_method
        @options_for_next_method = nil

        alias_method "_#{meth}_without_instrumentation", meth

        define_method(meth) do |*args, &blk|
          _instrument_method(meth, args, options, &blk)
        end
      end

      def singleton_method_added(meth)
        return unless @options_for_next_method

        options = @options_for_next_method
        @options_for_next_method = nil

        define_singleton_method("_#{meth}_without_instrumentation", method(meth))

        define_singleton_method(meth) do |*args, &blk|
          _instrument_method(meth, args, options, &blk)
        end
      end

      def _tags_for_method(meth, options, args)
        [
          "method:#{_naming_for_method(meth)}",
          "method_class:#{normalize_class_name(self)}"
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

      def _instrument_method(meth, args, options, &blk)
        with_tags(_tags_for_method(meth, options, args)) do
          increment("methods.count")
          _run_instrumented_method(meth, args, options, &blk)
        end
      end

      def _run_instrumented_method(meth, args, options, &blk)
        time("methods.timing") do
          capture_exception do
            self.send("_#{meth}_without_instrumentation", *args, &blk)
          end
        end
      rescue => e
        raise InstrumentAllTheThings::Exception.register(e)
      end

      def _naming_for_method(meth)
        ".#{meth}"
      end
    end
  end
end
