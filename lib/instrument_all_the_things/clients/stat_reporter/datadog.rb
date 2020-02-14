# frozen_string_literal: true

require 'datadog/statsd'

module InstrumentAllTheThings
  module Clients
    module StatReporter
      class DataDog < Datadog::Statsd
        %i[
          count
          distribution
          gauge
          histogram
          set
          time
          timing
        ].each do |meth|
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
end
