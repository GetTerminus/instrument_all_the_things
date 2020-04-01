# frozen_string_literal: true

module InstrumentAllTheThings
  module Instrumentors
    DEFAULT_TRACE_OPTIONS = {
      service: '',
      span_type: '',
      tags: {},
      span_name: 'method.execution'
    }.freeze

    TRACE_WRAPPER = proc do |opts, context|
      opts = if opts == true
               DEFAULT_TRACE_OPTIONS
             else
               DEFAULT_TRACE_OPTIONS.merge(opts)
             end

      proc do |klass, next_blk, actual_code|
        InstrumentAllTheThings.tracer.trace(
          opts[:span_name],
          tags: context[:tags] || {},
          service: opts[:service],
          resource: opts[:resource] || context.trace_name(klass),
          span_type: opts[:span_type]
        ) { next_blk.call(klass, actual_code) }
      end
    end
  end
end
