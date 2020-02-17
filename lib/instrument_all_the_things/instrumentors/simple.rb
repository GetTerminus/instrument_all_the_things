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

    ERROR_LOGGER = lambda do |exception, backtrace_cleaner|
    end

    ERROR_LOGGING_WRAPPER = lambda do |opts, context|
      opts = if opts == true
               DEFAULT_ERROR_LOGGING_OPTIONS
             else
               DEFAULT_ERROR_LOGGING_OPTIONS.merge(opts)
             end

      backtrace_cleaner = if opts[:exclude_bundle_path ] && defined?(Bundler)
                            bundle_path = Bundler.bundle_path.to_s
                            ->(trace) { trace.reject{|p| p.start_with?(bundle_path)} }
                          else
                            ->(trace) { trace }
                          end

      lambda do |next_blk, actual_code|
        next_blk.call(actual_code)
      rescue opts[:rescue_class] => e
        val = e.instance_variable_get(:@_logged_by_iatt)
        raise if val
        val = e.instance_variable_set(:@_logged_by_iatt, true)

        IATT.config&.logger&.error("An error occurred in #{context.trace_name}")
        IATT.config&.logger&.error(e.message)

        callstack = backtrace_cleaner.call(e.backtrace || [])

        callstack.each{|path| IATT.config&.logger&.error(path) }

        raise
      end
    end
  end
end
