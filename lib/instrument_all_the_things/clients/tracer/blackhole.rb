# frozen_string_literal: true

module InstrumentAllTheThings
  module Clients
    class Blackhole
      class Span
        def initialize; end

        def set_tag(name, value); end
      end

      def initialize
        reset!
      end

      def trace(_name, _options)
        yield Span.new
      end
    end
  end
end
