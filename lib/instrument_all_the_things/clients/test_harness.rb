# frozen_string_literal: true

module InstrumentAllTheThings
  module Clients
    class TestHarness
      attr_reader :emitted_values
      %i[
        count
        decrement
        distribution
        gauge
        histogram
        increment
        set
        time
        timing
      ].each do |meth|
        define_method(meth) do |*args, **kwargs, &_blk|
          @emitted_values[meth][args[0]] << {
            args: args[1..-1],
            kwargs: kwargs
          }
        end
      end

      def initialize
        reset!
      end

      def reset!
        @emitted_values = Hash.new do |h, k|
          h[k] = Hash.new do |h2, k2|
            h2[k2] = []
          end
        end
      end
    end
  end
end
