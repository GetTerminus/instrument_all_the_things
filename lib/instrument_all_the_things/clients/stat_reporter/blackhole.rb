# frozen_string_literal: true

module InstrumentAllTheThings
  module Clients
    module StatReporter
      class Blackhole
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
          end
        end
      end
    end
  end
end
