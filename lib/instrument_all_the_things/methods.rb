module InstrumentAllTheThings
  module Methods

    def self.included(other_klass)
      other_klass.extend(ClassMethods)
    end

    def _tags_for_method(meth)
      ["Method:#{_naming_for_method(meth)}"]
    end

    def _instrument_method(meth, args, options, &blk)
      InstrumentAllTheThings.with_tags(_tags_for_method(meth)) do
        InstrumentAllTheThings.transmitter.increment("methods.count")
        InstrumentAllTheThings.transmitter.time("methods.timing") do
          self.send("_#{meth}_without_instrumentation", *args, &blk)
        end
      end
    end

    def _naming_for_method(meth)
      "#{InstrumentAllTheThings.normalize_class_name(self.class.to_s)}##{meth}"
    end

    module ClassMethods
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
    end
  end
end
