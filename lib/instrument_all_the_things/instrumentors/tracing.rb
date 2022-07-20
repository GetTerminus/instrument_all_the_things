# frozen_string_literal: true

module InstrumentAllTheThings
  module Instrumentors
    DEFAULT_TRACE_OPTIONS = {
      service: '',
      span_type: '',
      tags: {},
      span_name: 'method.execution',
    }.freeze

    TRACE_WRAPPER = proc do |opts, context|
      opts = if opts == true
               DEFAULT_TRACE_OPTIONS.dup
             else
               DEFAULT_TRACE_OPTIONS.merge(opts)
             end

      span_name = opts.delete(:span_name)

      proc do |klass, next_blk, actual_code|
        passed_ops = opts.dup
        passed_ops[:resource] ||= context.trace_name(klass)
        passed_ops[:tags] ||= {}

        InstrumentAllTheThings.tracer.trace(span_name, **passed_ops) do
          next_blk.call(klass, actual_code)
        end
      end
    end
  end
end
