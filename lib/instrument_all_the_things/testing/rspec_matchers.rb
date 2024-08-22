# frozen_string_literal: true

# rubocop:todo Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

module InstrumentAllTheThings
  module Testing
    module RSpecMatchers
      def histogram_value(counter_name)
        stats = InstrumentAllTheThings.stat_reporter.emitted_values[:histogram][counter_name]
        stats.inject(0) { |l, n| l + n[:args][0] }
      end

      def distribution_values(distribution_name, with_tags: nil)
        stats = InstrumentAllTheThings.stat_reporter.emitted_values[:distribution][distribution_name]

        if with_tags && !stats.empty?
          stats = stats.select do |s|
            with_tags.all? { |t| s[:tags].include?(t) }
          end
        end

        stats&.map { |i| i[:args] }&.map(&:first) || []
      end

      def histogram_values(histogram_name, with_tags: nil)
        stats = InstrumentAllTheThings.stat_reporter.emitted_values[:histogram][histogram_name]

        if with_tags && !stats.empty?
          stats = stats.select do |s|
            with_tags.all? { |t| s[:tags].include?(t) }
          end
        end

        stats&.map { |i| i[:args] }&.map(&:first) || []
      end

      def timing_values(timing_name, with_tags: nil)
        stats = InstrumentAllTheThings.stat_reporter.emitted_values[:timing][timing_name]

        if with_tags && !stats.empty?
          stats = stats.select do |s|
            with_tags.all? { |t| s[:tags].include?(t) }
          end
        end

        stats&.map { |i| i[:args] }&.map(&:first) || []
      end

      def set_value(counter_name, with_tags: nil)
        stats = InstrumentAllTheThings.stat_reporter.emitted_values[:set][counter_name]

        if with_tags && !stats.empty?
          stats = stats.select do |s|
            with_tags.all? { |t| s[:tags].include?(t) }
          end
        end

        data = stats&.map { |i| i[:args] }&.map(&:first)
        data ? data.uniq.length : 0
      end

      def gauge_value(counter_name, with_tags: nil)
        stats = InstrumentAllTheThings.stat_reporter.emitted_values[:gauge][counter_name]

        if with_tags && !stats.empty?
          stats = stats.select do |s|
            with_tags.all? { |t| s[:tags].include?(t) }
          end
        end
        stats.last&.fetch(:args)&.first
      end

      def counter_value(counter_name, with_tags: nil)
        stats = InstrumentAllTheThings.stat_reporter.emitted_values[:count][counter_name]
        if with_tags && !stats.empty?
          stats = stats.select do |s|
            with_tags.all? { |t| s[:tags].include?(t) }
          end
        end
        stats.inject(0) { |l, n| l + n[:args][0] }
      end

      def emitted_spans(filtered_by: nil)
        sleep 0.01
        traces = InstrumentAllTheThings::Testing::TraceTracker.tracker.traces.map(&:dup)
        if filtered_by
          filtered_by.transform_keys!(&:to_s)
          traces.select! { |t| filtered_by < t }
        end

        traces
      end
    end
  end
end

# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
