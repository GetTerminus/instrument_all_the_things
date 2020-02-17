# frozen_string_literal: true

module InstrumentAllTheThings
  module Instrumentors
    DEFAULT_TRACE_OPTIONS = {
      service: '',
      span_type: '',
      tags: {},
      span_name: 'method.execution'
    }.freeze

    TRACE_WRAPPER = lambda do |opts, context|
      opts = if opts == true
               DEFAULT_TRACE_OPTIONS
             else
               DEFAULT_TRACE_OPTIONS.merge(opts)
             end

      lambda do |next_blk, actual_code|
        InstrumentAllTheThings.config.tracer.trace(
          opts[:span_name],
          tags: opts[:tags],
          service: opts[:service],
          resource: opts[:resource] || context.trace_name,
          span_type: opts[:span_type]
        ) { next_blk.call(actual_code) }
      end
    end
  end
end
