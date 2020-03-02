# frozen_string_literal: true

module InstrumentAllTheThings
  module Instrumentors
    DEFAULT_EXECUTION_COUNT_AND_TIMING_OPTIONS = { }.freeze

    EXECUTION_COUNT_AND_TIMING_WRAPPER = proc do |opts, context|
      proc do |klass, next_blk, actual_code|
        InstrumentAllTheThings.increment("#{context.stats_name(klass)}.executed")

        InstrumentAllTheThings.time("#{context.stats_name(klass)}.duration") do
          next_blk.call(klass, actual_code)
        end
      rescue
        InstrumentAllTheThings.increment("#{context.stats_name(klass)}.errored")
        raise
      end
    end
  end
end
