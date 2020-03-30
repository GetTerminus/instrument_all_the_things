# frozen_string_literal: true

module InstrumentAllTheThings
  module Instrumentors
    DEFAULT_EXECUTION_COUNT_AND_TIMING_OPTIONS = {}.freeze

    EXECUTION_COUNT_AND_TIMING_WRAPPER = proc do |_opts, context|
      proc do |klass, next_blk, actual_code|
        context.tags ||= []

        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        next_blk.call(klass, actual_code)
      rescue StandardError
        InstrumentAllTheThings.increment("#{context.stats_name(klass)}.errored", { tags: context.tags })
        raise
      ensure
        InstrumentAllTheThings.increment("#{context.stats_name(klass)}.executed", { tags: context.tags })
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        InstrumentAllTheThings.timing("#{context.stats_name(klass)}.duration", ((ending - starting) * 1000).to_i, { tags: context.tags })
      end
    end
  end
end
