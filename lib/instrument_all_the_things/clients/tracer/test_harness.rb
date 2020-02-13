module InstrumentAllTheThings
  module Clients
    class Blackhole
      class Span
        attr_accessor :tags
        def initialize
          self.tags = {}
        end

        def set_tag(name, value)
          tags[name] = value
        end
      end

      attr_accessor :spans

      def initialize
        reset!
      end

      def trace(name, options)
        span = Span.new
        spans << span
        yield span
      end

      def reset!
        self.spans = []
      end
    end
  end
end
