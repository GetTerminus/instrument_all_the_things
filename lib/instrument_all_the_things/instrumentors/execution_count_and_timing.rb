# frozen_string_literal: true

module InstrumentAllTheThings
  module Instrumentors
    DEFAULT_EXECUTION_COUNT_AND_TIMING_OPTIONS = {}.freeze

    EXECUTION_COUNT_AND_TIMING_WRAPPER = proc do |_opts, context|
      proc do |klass, next_blk, actual_code|
        context.tags ||= []

        InstrumentAllTheThings.increment("#{context.stats_name(klass)}.executed", tags: context.tags)
        InstrumentAllTheThings.time("#{context.stats_name(klass)}.duration", tags: context.tags) do
          next_blk.call(klass, actual_code)
        end
      rescue StandardError
        InstrumentAllTheThings.increment("#{context.stats_name(klass)}.errored", tags: context.tags)
        raise
      end
    end
  end
end
