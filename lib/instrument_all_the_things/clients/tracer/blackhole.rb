module InstrumentAllTheThings
  module Clients
    class Blackhole
      class Span
        def initialize
        end

        def set_tag(name, value)
        end
      end


      def initialize
        reset!
      end

      def trace(name, options)
        yield Span.new
      end
    end
  end
end
