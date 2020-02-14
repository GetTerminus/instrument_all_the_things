# frozen_string_literal: true

require_relative './instrumentors/simple'

module InstrumentAllTheThings
  class MethodInstrumentor
    INSTRUMENTOR = {
      trace: TRACE_WRAPPER
    }.freeze

    DEFAULT_OPTIONS = {
      trace: true
    }.freeze

    attr_accessor :options, :instrumentor

    def initialize(options)
      self.options = options.merge(DEFAULT_OPTIONS)

      procs = INSTRUMENTOR.collect do |type, builder|
        next unless self.options[type]

        builder.call(self.options[type])
      end.compact

      self.instrumentor = combine_procs(procs)

      freeze
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
