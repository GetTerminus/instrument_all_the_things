# frozen_string_literal: true

module InstrumentAllTheThings
  module Testing
    module RSpecMatchers
      def histogram_value(counter_name)
        stats = IATT.config.stat_reporter.emitted_values[:histogram][counter_name]
        stats.inject(0){|l, n| l + n[:args][0] }
      end
      def counter_value(counter_name)
        stats = IATT.config.stat_reporter.emitted_values[:count][counter_name]
        stats.inject(0){|l, n| l + n[:args][0] }
      end

      def flush_traces
        Datadog.tracer&.writer&.worker&.flush_data
      end

      def emitted_spans(filtered_by: nil)
        sleep 0.01
        traces = IATT::Testing::TraceTracker.tracker.traces.map(&:dup)
        if filtered_by
          filtered_by.transform_keys!(&:to_s)
          traces.select! { |t| filtered_by < t }
        end

        traces
      end
    end
  end
end
