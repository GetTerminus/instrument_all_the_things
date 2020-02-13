# frozen_string_literal: true

require 'datadog/statsd'

module InstrumentAllTheThings
  module Clients
    class DataDog < Datadog::Statsd
      %i{
        count
        decrement
        distribution
        gauge
        histogram
        increment
        set
        time
        timing
      }.each do |meth|
        define_method(meth) do |*args, **kwarg, &blk|
          args[0] = stat_prefix + args[0]
          super(*args, **kwarg, &blk)
        end
      end

      private

      def stat_prefix
        'omg'
      end
    end
  end
end
