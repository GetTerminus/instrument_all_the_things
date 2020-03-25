# frozen_string_literal: true

module InstrumentAllTheThings
  module Instrumentors
    DEFAULT_EXECUTION_COUNT_AND_TIMING_OPTIONS = { }.freeze

    EXECUTION_COUNT_AND_TIMING_WRAPPER = proc do |opts, context|
      proc do |klass, next_blk, actual_code|
        tags = opts.is_a?(Hash) && opts[:tags] ? { tags: opts[:tags] } : {}
        InstrumentAllTheThings.increment("#{context.stats_name(klass)}.executed", tags)

        InstrumentAllTheThings.time("#{context.stats_name(klass)}.duration", tags) do
          next_blk.call(klass, actual_code)
        end
      rescue
        InstrumentAllTheThings.increment("#{context.stats_name(klass)}.errored", tags)
        raise
      end
    end
  end
end
