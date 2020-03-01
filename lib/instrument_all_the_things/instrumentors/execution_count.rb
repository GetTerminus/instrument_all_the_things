# frozen_string_literal: true

module InstrumentAllTheThings
  module Instrumentors
    DEFAULT_EXECUTION_COUNT_OPTIONS = { }.freeze

    EXECUTION_COUNT_WRAPPER = proc do |opts, context|
      proc do |klass, next_blk, actual_code|
        InstrumentAllTheThings.increment("#{context.stats_name(klass)}.executed")
        next_blk.call(klass, actual_code)
      rescue
        InstrumentAllTheThings.increment("#{context.stats_name(klass)}.errored")
        raise
      end
    end
  end
end
