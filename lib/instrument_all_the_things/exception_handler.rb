require 'instrument_all_the_things/core_extensions/exception'

module InstrumentAllTheThings
  module ExceptionHandler
    include HelperMethods

    class << self
      def capture(options = {}, &blk)
        blk.call
      rescue => e
        register(e, options)
        raise
      end

      def register(exception, options = {})
        return exception unless exception.is_a?(Exception) && !exception._instrument_all_the_things_reported
        options ||= {}

        exception.tap do |ex|
          [
            "exceptions.count",
            ("#{options[:as]}.exceptions.count" if options[:as])
          ].compact.each do |key|
            instrumentation_increment(key)
            ex._instrument_all_the_things_reported = true
          end
        end
      end
    end
  end
end
