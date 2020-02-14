# frozen_string_literal: true

module InstrumentAllTheThings
  module Testing
    class TraceTracker
      attr_reader :traces

      def self.tracker
        @tracker ||= new
      end

      def initialize
        reset!
      end

      def reset!
        @traces = []
      end

      def <<(val)
        @traces = @traces.concat(MessagePack.load(val[:body]).flatten)
      end
    end
  end
end
