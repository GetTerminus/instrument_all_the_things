require 'instrument_all_the_things/core_extensions/exception'

module InstrumentAllTheThings
  module ExceptionHandler
    include HelperMethods

    class << self
      def capture(&blk)
        blk.call
      rescue => e
        register(e)
        raise
      end

      def register(exception)
        return exception unless exception.is_a?(Exception) && !exception._instrument_all_the_things_reported

        exception.tap do |ex|
          increment(
            "exceptions.count",
            tags: ["exception_class:#{normalize_class_name(ex.class)}"]
          )
          ex._instrument_all_the_things_reported = true
        end
      end
    end
  end
end
