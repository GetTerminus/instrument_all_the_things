# frozen_string_literal: true

module InstrumentAllTheThings
  module Testing
    module RSpecMatchers
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
