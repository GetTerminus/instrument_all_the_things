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

    DEFAULT_ERROR_LOGGING_OPTIONS = {
      exclude_bundle_path: true,
      rescue_class: StandardError,
    }.freeze

    ERROR_LOGGING_WRAPPER = lambda do |opts, context|
      opts = if opts == true
               DEFAULT_ERROR_LOGGING_OPTIONS
             else
               DEFAULT_ERROR_LOGGING_OPTIONS.merge(opts)
             end

      lambda do |next_blk, actual_code|
        next_blk.call(actual_code)
      rescue opts[:rescue_class] => e
        IATT.config&.logger&.error("An error occurred in #{context.trace_name}")
        IATT.config&.logger&.error(e.message)

        callstack = if opts[:exclude_bundle_path ] && defined?(Bundler) && e.backtrace
                      bundle_path = Bundler.bundle_path.to_s
                      e.backtrace.reject do |path|
                        path.start_with?(bundle_path)
                      end
                    else
                      e.backtrace || []
                    end

        callstack.each{|path| IATT.config&.logger&.error(path) }
      end
    end
  end
end
