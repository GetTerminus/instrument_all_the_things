# frozen_string_literal: true

require 'ddtrace'

# https://github.com/DataDog/dd-trace-rb/blob/master/docs/UpgradeGuide.md#between-threads
class Thread
  def self.new_traced
    trace = Datadog::Tracing.active_trace

    if trace
      trace_digest = trace.to_digest
      Thread.new do |*args|
         # Inherits trace properties from the trace digest
        Datadog::Tracing.trace(trace.name, continue_from: trace_digest) do |_span, trace|
          trace.id == trace_digest.trace_id
          yield(*args)
        end
      end
    else
      Thread.new do |*args|
        yield(*args)
      end
    end
  end
end
