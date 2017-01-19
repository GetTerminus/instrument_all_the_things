module InstrumentAllTheThings
  module Exception
    include HelperMethods

    class << self
      def register(exception)
       increment("exceptions.count",
          tags: [
            "exception_class:#{normalize_class_name(exception.class)}"
          ]
        )
      end
    end
  end
end
