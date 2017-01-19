module InstrumentAllTheThings
  module Exception
    class << self
      def register(exception)
        InstrumentAllTheThings.transmitter.increment("exceptions.count",
          tags: [
            "exception_class:#{InstrumentAllTheThings.normalize_class_name(exception.class)}"
          ]
        )
      end
    end
  end
end
