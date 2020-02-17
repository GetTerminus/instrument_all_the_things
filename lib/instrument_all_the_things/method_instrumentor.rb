# frozen_string_literal: true

require_relative './instrumentors/simple'

module InstrumentAllTheThings
  class MethodInstrumentor
    WAPPERS = {
      trace: Instrumentors::TRACE_WRAPPER,
      error_logging: Instrumentors::ERROR_LOGGING_WRAPPER
    }.freeze

    DEFAULT_OPTIONS = {
      trace: true
    }.freeze

    attr_accessor :options, :instrumentor

    def initialize(options)
      self.options = DEFAULT_OPTIONS.merge(options)

      build_instrumentor

      freeze
    end

    def build_instrumentor
      procs = WAPPERS.collect do |type, builder|
        next unless options[type]

        builder.call(options[type], options[:context])
      end.compact

      self.instrumentor = combine_procs(procs)
    end

    def invoke(&blk)
      instrumentor.call(blk)
    end

    private

    def combine_procs(procs)
      # I know it's crazy, but this wraps procs which take "Next Block"
      # and "Final Block"
      procs.inject(->(f) { f.call }) do |next_blk, current_blk|
        proc { |final| current_blk.call(next_blk, final) }
      end
    end
  end
end
