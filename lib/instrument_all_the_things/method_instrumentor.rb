# frozen_string_literal: true

require_relative './instrumentors/all'

module InstrumentAllTheThings
  class MethodInstrumentor
    WRAPPERS = {
      # Note that the order of these hash keys are applied top to bottom, with the first inserted key
      # being the inner most wrapper
      gc_stats: Instrumentors::GC_STATS_WRAPPER,
      error_logging: Instrumentors::ERROR_LOGGING_WRAPPER,
      execution_counts_and_timing: Instrumentors::EXECUTION_COUNT_AND_TIMING_WRAPPER,
      trace: Instrumentors::TRACE_WRAPPER,
    }.freeze

    DEFAULT_OPTIONS = {
      trace: true,
      gc_stats: true,
      error_logging: true,
      execution_counts_and_timing: true
    }.freeze

    attr_accessor :options, :instrumentor

    def initialize(options)
      self.options = DEFAULT_OPTIONS.merge(options)

      build_instrumentor

      freeze
    end

    def build_instrumentor
      procs = WRAPPERS.collect do |type, builder|
        next unless options[type]

        builder.call(options[type], options[:context])
      end.compact

      self.instrumentor = combine_procs(procs)
    end

    def invoke(klass:, &blk)
      instrumentor.call(klass, blk)
    end

    private

    def combine_procs(procs)
      # I know it's crazy, but this wraps procs which take "Next Block"
      # and "Final Block"
      procs.inject(->(_, f) { f.call }) do |next_blk, current_blk|
        proc { |k, final| current_blk.call(k, next_blk, final) }
      end
    end
  end
end
