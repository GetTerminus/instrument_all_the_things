# frozen_string_literal: true

require 'ddtrace'

# https://github.com/DataDog/dd-trace-rb/blob/master/docs/UpgradeGuide.md#between-threads
class Thread
  def self.new_traced
    active_trace = Datadog::Tracing.active_trace
    trace_digest = active_trace.to_digest

    Thread.new do |*args|
      Datadog::Tracing.trace(trace.name, continue_from: trace_digest) do |_span, trace|
        trace.id = trace_digest.trace_id
        yield(*args)
      end
    end
  end
end
